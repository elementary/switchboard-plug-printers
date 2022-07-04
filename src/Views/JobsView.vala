// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
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

public class Printers.JobsView : Gtk.Frame {
    public Printer printer { get; construct; }
    private Gtk.ListBox list_box;
    private Gtk.Button clear_button;

    public JobsView (Printer printer) {
        Object (printer: printer);
    }

    construct {
        var alert = new Granite.Placeholder (_("Print Queue Is Empty")) {
            description = _("There are no pending jobs in the queue.")
        };

        list_box = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        list_box.set_placeholder (alert);
        list_box.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) update_header);
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) compare);

        var scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            child = list_box
        };

        var clear_button_label = new Gtk.Label (_("Clear All"));
        var clear_button_image = new Gtk.Image.from_icon_name ("edit-clear-all-symbolic") {
            pixel_size = 16,
            halign = Gtk.Align.START
        };

        var clear_button_indicator_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        clear_button_indicator_box.append (clear_button_image);
        clear_button_indicator_box.append (clear_button_label);

        clear_button = new Gtk.Button () {
            sensitive = list_box.observe_children ().get_n_items () > 0,
            child = clear_button_indicator_box
        };
        clear_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (clear_button);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (scrolled);
        box.append (actionbar);

        child = box;

        refresh_job_list ();

        unowned Cups.Notifier notifier = Cups.Notifier.get_default ();
        notifier.job_created.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
            if (printer.dest.name != name) {
                return;
            }

            var jobs_ = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs_) {
                if (job.uid == job_id) {
                    list_box.append (new JobRow (printer, job));
                    break;
                }
            }

            clear_button.sensitive = list_box.observe_children ().get_n_items () > 0;
        });

        clear_button.clicked.connect (() => clear_queue ());
    }

    // Sort all ongoing jobs first, otherwise sort in descending order of displayed time (null last)
    static int compare (JobRow a, JobRow b) {
        if (a.job.is_ongoing && !b.job.is_ongoing) {
            return -1;
        } else if (!a.job.is_ongoing && b.job.is_ongoing) {
            return 1;
        } else {
            var timea = (((JobRow)a).job.get_display_time ());
            var timeb = (((JobRow)b).job.get_display_time ());
            if (timea == null) {
                if (timeb == null) {
                    return 0;
                } else {
                    return 1;
                }
            } else if (timeb == null) {
                return -1;
            } else {
                return timeb.compare (timea);
            }
        }
    }

    [CCode (instance_pos = -1)]
    private void update_header (JobRow row1, JobRow? row2) {
        if (!row1.job.is_ongoing && (row2 == null || row2.job.is_ongoing)) {
            var label = new Gtk.Label (_("Completed Jobs")) {
                xalign = 0,
                margin_start = 3,
                margin_end = 3,
                margin_top = 3,
                margin_bottom = 3
            };
            label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
            row1.set_header (label);
        } else {
            row1.set_header (null);
        }
    }

    public void clear_queue () {
        var dialog = new ClearQueueDialog (printer) {
            transient_for = (Gtk.Window) get_root ()
        };
        dialog.response.connect ((response_id) => {
            dialog.destroy ();

            if (response_id == Gtk.ResponseType.OK) {
                var children = list_box.observe_children ();
                for (var index = 0; index < children.get_n_items (); index++) {
                    var row = (JobRow) children.get_item (index);
                    var job = row.job;
                    job.pause (); // Purging pending/in_progress jobs does not always remove canceled job
                    job.purge ();
                }

                refresh_job_list ();
            }
        });

        dialog.present ();
    }

    private void refresh_job_list () {
        var children = list_box.observe_children ();
        for (var index = 0; index < children.get_n_items (); index++) {
            list_box.remove ((Gtk.Widget) children.get_item (index));
        }

        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var job in jobs) {
            list_box.append (new JobRow (printer, job));
        }

        clear_button.sensitive = list_box.observe_children ().get_n_items () > 0;
    }
}
