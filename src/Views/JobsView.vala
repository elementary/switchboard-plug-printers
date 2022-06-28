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
    private Printer printer;
    private Gtk.ListBox list_box;
    public uint n_jobs { get; private set; }

    public JobsView (Printer printer) {
        this.printer = printer;

        var alert = new Granite.Widgets.AlertView (_("Print Queue Is Empty"), _("There are no pending jobs in the queue."), "");
        alert.show_all ();

        list_box = new Gtk.ListBox ();
        list_box.selection_mode = Gtk.SelectionMode.SINGLE;
        list_box.set_placeholder (alert);
        list_box.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) update_header);
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) compare);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (list_box);
        scrolled.show_all ();
        add (scrolled);

        refresh_job_list ();

        unowned Cups.Notifier notifier = Cups.Notifier.get_default ();
        notifier.job_created.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
            if (printer.dest.name != name) {
                return;
            }

            var jobs_ = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs_) {
                if (job.uid == job_id) {
                    list_box.add (new JobRow (printer, job));
                    break;
                }
            }

            n_jobs = list_box.get_children ().length ();
        });
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
            var label = new Gtk.Label (_("Completed Jobs"));
            label.xalign = 0;
            label.margin = 3;
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            row1.set_header (label);
        } else {
            row1.set_header (null);
        }
    }

    public void clear_queue () {
        var dialog = new ClearQueueDialog (printer) {
            transient_for = (Gtk.Window) get_toplevel ()
        };
        dialog.response.connect ((response_id) => {
            dialog.destroy ();

            if (response_id == Gtk.ResponseType.OK) {
                list_box.@foreach ((row) => {
                    var job = ((JobRow)row).job;
                    job.purge ();
                });

                refresh_job_list ();
            }
        });

        dialog.present ();
    }

    private void refresh_job_list () {
        list_box.@foreach ((row) => {
            list_box.remove (row);
        });

        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var job in jobs) {
            if (!job.canceled_or_aborted) {
                list_box.add (new JobRow (printer, job));
            }
        }

        n_jobs = list_box.get_children ().length ();
    }
}
