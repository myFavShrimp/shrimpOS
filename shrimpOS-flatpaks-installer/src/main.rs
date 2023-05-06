use std::process::Stdio;
use tokio::io::AsyncBufReadExt;

use gtk::glib::clone;
use gtk::prelude::{BoxExt, ButtonExt, GtkWindowExt};
use relm4::gtk::traits::{TextBufferExt, WidgetExt};
use relm4::{gtk, Component, ComponentParts, ComponentSender, RelmApp, RelmWidgetExt};
use tokio::io::BufReader;

struct AppModel {
    flatpaks: Vec<String>,
    install_progress: InstallProgress,
}

#[derive(Debug, Clone)]
enum InstallProgress {
    NotRunning,
    Running(String),
    Finished(String),
}

#[derive(Debug)]
enum AppInput {
    Quit,
    Install,
}

#[derive(Debug)]
pub enum AppOutput {
    InstallOutput(String),
}

#[derive(Debug)]
pub enum CmdOutput {
    Running(String),
    Finished,
}

struct AppWidgets {
    output_buffer: gtk::TextBuffer,
    close_button: gtk::Button,
    install_button: gtk::Button,
}

impl Component for AppModel {
    type Init = Vec<String>;
    type Input = AppInput;
    type Output = AppOutput;
    type Root = gtk::Window;
    type Widgets = AppWidgets;
    type CommandOutput = CmdOutput;

    fn init_root() -> Self::Root {
        gtk::Window::builder()
            .title("New applications available!")
            .default_width(800)
            .default_height(600)
            .resizable(false)
            .deletable(false)
            .modal(true)
            .build()
    }

    fn init(
        init: Self::Init,
        window: &Self::Root,
        sender: ComponentSender<Self>,
    ) -> relm4::ComponentParts<Self> {
        let model = AppModel {
            flatpaks: init.clone(),
            install_progress: InstallProgress::NotRunning,
        };

        // boxes
        let h_button_box = gtk::CenterBox::builder()
            .orientation(gtk::Orientation::Horizontal)
            .halign(gtk::Align::End)
            .valign(gtk::Align::End)
            .build();

        let v_main_box = gtk::Box::builder()
            .orientation(gtk::Orientation::Vertical)
            .spacing(15)
            .margin_bottom(10)
            .margin_top(10)
            .margin_end(10)
            .margin_start(10)
            .build();

        let v_flatpaks_box = gtk::Box::builder()
            .orientation(gtk::Orientation::Vertical)
            .build();
        let scrollable = gtk::ScrolledWindow::builder()
            .height_request(250)
            .child(&v_flatpaks_box)
            .has_frame(true)
            .build();
        scrollable.inline_css("border-radius: 5px;");

        // widgets
        let close_button = gtk::Button::with_label("Close");
        close_button.connect_clicked(clone!(@strong sender => move |_| {
            sender.input(AppInput::Quit);
        }));

        let install_button = gtk::Button::with_label("Install");
        install_button.connect_clicked(clone!(@strong sender => move |_| {
            sender.input(AppInput::Install);
        }));

        let label = gtk::Label::builder().label("Install Flatpaks").build();
        label.set_margin_all(5);

        let output_buffer = gtk::TextBuffer::builder().build();
        let output = gtk::TextView::builder()
            .buffer(&output_buffer)
            .editable(false)
            .monospace(true)
            .left_margin(10)
            .right_margin(10)
            .top_margin(10)
            .height_request(250)
            .wrap_mode(gtk::WrapMode::Word)
            .pixels_below_lines(8)
            .build();
        output.inline_css("border-radius: 5px;");

        init.iter().for_each(|item| {
            let flatpak_label = gtk::Label::builder().label(item).build();
            v_flatpaks_box.append(&flatpak_label);
        });

        // window composition
        window.set_child(Some(&v_main_box));
        v_main_box.append(&label);
        v_main_box.append(&scrollable);
        v_main_box.append(&output);
        v_main_box.append(&h_button_box);
        h_button_box.set_margin_all(5);
        h_button_box.set_start_widget(Some(&close_button));
        h_button_box.set_end_widget(Some(&install_button));

        let widgets = AppWidgets {
            output_buffer,
            install_button,
            close_button,
        };

        ComponentParts { model, widgets }
    }

    fn update(&mut self, message: Self::Input, sender: ComponentSender<Self>, root: &Self::Root) {
        match message {
            AppInput::Quit => root.close(),
            AppInput::Install => {
                let flatpaks = self.flatpaks.clone();
                sender.command(|out, shutdown| {
                    shutdown
                        .register(async move {
                            let mut process = dbg!(tokio::process::Command::new("flatpak")
                                .arg("install")
                                .args(dbg!(flatpaks))
                                .stdout(Stdio::piped())
                                .stderr(Stdio::piped())
                                .kill_on_drop(true))
                                .spawn()
                                .unwrap();

                            let stdout = process.stdout.take().unwrap();
                            let sterr = process.stderr.take().unwrap();

                            let mut stdout_reader = BufReader::new(stdout).lines();
                            let mut sterr_reader = BufReader::new(sterr).lines();

                            loop {
                                tokio::select! {
                                    result = stdout_reader.next_line() => {
                                        match result {
                                            Ok(Some(line)) => out.send(CmdOutput::Running(String::from(line))).unwrap(),
                                            Err(e) => out.send(CmdOutput::Running(e.to_string())).unwrap(),
                                            Ok(None)=> {}
                                        };
                                    }
                                    result = sterr_reader.next_line() => {
                                        match result {
                                            Ok(Some(line)) => out.send(CmdOutput::Running(String::from(line))).unwrap(),
                                            Err(e) => out.send(CmdOutput::Running(e.to_string())).unwrap(),
                                            Ok(None)=> {}
                                        };
                                    }
                                    result = process.wait() => {
                                        match result {
                                            Ok(_exit_code) => {}
                                            Err(_e) => {},
                                        };
                                        break;
                                    }
                                }
                            }

                            out.send(CmdOutput::Finished).unwrap();
                        })
                        .drop_on_shutdown()
                })
            }
        }
    }

    fn update_cmd(
        &mut self,
        message: Self::CommandOutput,
        _sender: ComponentSender<Self>,
        _root: &Self::Root,
    ) {
        match message {
            CmdOutput::Running(output) => {
                let current_output = match self.install_progress.clone() {
                    InstallProgress::NotRunning => output,
                    InstallProgress::Running(mut past_output)
                    | InstallProgress::Finished(mut past_output) => {
                        past_output.push_str(&format!("\n{}", output));
                        past_output
                    }
                };
                self.install_progress = InstallProgress::Running(current_output);
            }
            CmdOutput::Finished => {
                match self.install_progress.clone() {
                    InstallProgress::NotRunning | InstallProgress::Finished(_) => {
                        panic!("Installation should be running")
                    }
                    InstallProgress::Running(output) => {
                        self.install_progress = InstallProgress::Finished(output)
                    }
                };
            }
        }
    }

    fn update_view(&self, widgets: &mut Self::Widgets, _sender: ComponentSender<Self>) {
        match dbg!(&self.install_progress) {
            InstallProgress::NotRunning => {
                widgets.close_button.set_sensitive(true);
                widgets.install_button.set_sensitive(true);
            }
            InstallProgress::Running(output) => {
                widgets.close_button.set_sensitive(false);
                widgets.install_button.set_sensitive(false);

                widgets.output_buffer.set_text(output);
            }
            InstallProgress::Finished(output) => {
                widgets.close_button.set_sensitive(true);
                widgets.install_button.set_sensitive(true);

                widgets.output_buffer.set_text(output);
            }
        }
    }
}

fn installed_flatpaks() -> Vec<String> {
    let flatpak_output = std::process::Command::new("flatpak")
        .args(["list", "--columns=application"])
        .output()
        .unwrap();
    let output = String::from_utf8(flatpak_output.stdout).unwrap();
    output.as_str().lines().fold(Vec::new(), |mut acc, line| {
        if line.contains("Application ID") {
            return acc;
        }

        acc.push(line.to_string());
        acc
    })
}

fn flatpaks_to_install() -> Vec<String> {
    let flatpak_output = std::process::Command::new("cat")
        .args(["/etc/shrimpos/flatpaks"])
        .output()
        .unwrap();
    let output = String::from_utf8(flatpak_output.stdout).unwrap();
    output.as_str().lines().fold(Vec::new(), |mut acc, line| {
        acc.push(line.to_string());
        acc
    })
}

fn main() {
    let installed_flats = dbg!(installed_flatpaks());

    let needed_flatpaks =
        dbg!(flatpaks_to_install())
            .iter()
            .fold(Vec::new(), |mut acc, flatpak| {
                if !installed_flats.contains(flatpak) {
                    acc.push(flatpak.clone());
                }

                acc
            });

    if !needed_flatpaks.is_empty() {
        let app = RelmApp::new("shrimpos.flatpak.installer");
        app.run::<AppModel>(needed_flatpaks);
    }
}
