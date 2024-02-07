/*-
 * Copyright 2015 - 2022 elementary, Inc. (https://elementary.io)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.JobRow : Gtk.ListBoxRow {
    public Printers.Job job { get; construct set; }
    public Printer printer { get; construct set; }

    private Gtk.Button start_pause_button;
    private Gtk.Image job_state_icon;
    private Gtk.Revealer action_revealer;
    private Gtk.Label date_label;
    private Gtk.Label state_label;

    private static Gtk.SizeGroup size_group;

    public JobRow (Printer printer, Printers.Job job) {
        Object (
            job: job,
            printer: printer
        );
    }

    static construct {
        size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
    }

    construct {
        var icon = new Gtk.Image.from_gicon (job.get_file_icon ());
        icon.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        job_state_icon = new Gtk.Image () {
            gicon = job.state_icon (),
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var icon_overlay = new Gtk.Overlay () {
            child = icon
        };
        icon_overlay.add_overlay (job_state_icon);

        var title = new Gtk.Label (job.title) {
            halign = Gtk.Align.START,
            hexpand = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        state_label = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.END
        };
        state_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        date_label = new Gtk.Label (Granite.DateTime.get_relative_datetime (job.creation_time)) {
            halign = Gtk.Align.END
        };
        date_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic") {
            tooltip_text = _("Cancel")
        };
        cancel_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        cancel_button.add_css_class (Granite.STYLE_CLASS_ACCENT);
        cancel_button.add_css_class ("red");

        start_pause_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        size_group.add_widget (start_pause_button);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            margin_start = 6
        };
        action_box.append (cancel_button);
        action_box.append (start_pause_button);

        action_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = action_box
        };

        var grid = new Gtk.Grid () {
            column_spacing = 6
        };
        grid.attach (icon_overlay, 0, 0, 1, 2);
        grid.attach (title, 1, 0);
        grid.attach (state_label, 1, 1);
        grid.attach (date_label, 2, 0, 1, 2);
        grid.attach (action_revealer, 3, 0, 1, 2);

        child = grid;

        update_state ();

        job.state_changed.connect (update_state);

        start_pause_button.clicked.connect (() => {
            unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
            if (job.state == CUPS.IPP.JobState.PROCESSING ||
                job.state == CUPS.IPP.JobState.PENDING) {

                try {
                    pk_helper.job_set_hold_until (job.uid, "indefinite");
                } catch (Error e) {
                    critical (e.message);
                }
            } else if (job.state == CUPS.IPP.JobState.HELD) {
                try {
                    pk_helper.job_set_hold_until (job.uid, "no-hold");
                } catch (Error e) {
                    critical (e.message);
                }
            } else {
                critical ("Unexpected job state when trying to pause or resume");
            }
        });

        cancel_button.clicked.connect (() => {
            unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
            try {
                pk_helper.job_cancel_purge (job.uid, false);
                start_pause_button.sensitive = false;
                cancel_button.sensitive = false;
            } catch (Error e) {
                critical (e.message);
            }
        });
    }

    private void update_state () {
        job_state_icon.gicon = job.state_icon ();

        if (job.state == CUPS.IPP.JobState.HELD) {
            start_pause_button.label = _("Resume");
            action_revealer.reveal_child = true;
        } else if (job.state == CUPS.IPP.JobState.PROCESSING ||
                   job.state == CUPS.IPP.JobState.PENDING) {

            start_pause_button.label = _("Pause");
            action_revealer.reveal_child = true;
        } else {
            action_revealer.reveal_child = false;
        }

        state_label.label = job.translated_job_state ();
        var time = job.get_display_time ();
        if (time != null) {
            date_label.label = Granite.DateTime.get_relative_datetime (time);
        } else {
            date_label.label = null;
        }

        changed ();
    }
}
