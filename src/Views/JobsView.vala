// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Pantheon Developers (https://launchpad.net/switchboard-plug-printers)
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
    private const string PRIVACY_KEY = "remember-recent-files";
    private Gtk.ListBox list_box;
    private Granite.Widgets.AlertView empty_alert;
    private Granite.Widgets.AlertView privacy_alert;

    public Settings gnome_privacy_settings { get; construct; }
    public Printer printer { get; construct; }

    public JobsView (Printer printer) {
        Object (printer: printer);
    }

    construct {
        empty_alert = new Granite.Widgets.AlertView (
            _("Print Queue Is Empty"),
            _("There are no pending jobs in the queue."),
            ""
        );
        empty_alert.show_all ();

        privacy_alert = new Granite.Widgets.AlertView (
            _("Print History Is Inaccessible"),
            _("The Privacy settings do not permit the job queue to be shown"),
            ""
        );
        privacy_alert.show_all ();

        list_box = new Gtk.ListBox ();
        list_box.selection_mode = Gtk.SelectionMode.SINGLE;
        list_box.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) update_header);
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) compare);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (list_box);
        scrolled.show_all ();

        add (scrolled);

        gnome_privacy_settings = new Settings ("org.gnome.desktop.privacy");
        gnome_privacy_settings.changed.connect ((key) => {
            if (key == PRIVACY_KEY) {
                update_privacy ();
            }
        });

        update_privacy ();

        unowned Cups.Notifier notifier = Cups.Notifier.get_default ();
        notifier.job_created.connect (
            (text, printer_uri, name, state, state_reasons, is_accepting_jobs,
            job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {

            if (!gnome_privacy_settings.get_boolean (PRIVACY_KEY)) {
                return;
            }

            if (printer.dest.name != name) {
                return;
            }

            var jobs_ = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs_) {
                if (job.cjob.id == job_id) {
                    list_box.add (new JobRow (printer, job));
                    break;
                }
            }
        });
    }

    static int compare (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
        var timea = (((JobRow)a).job.get_used_time ());
        var timeb = (((JobRow)b).job.get_used_time ());
        return timeb.compare (timea);
    }

    private void update_privacy () {
        if ( gnome_privacy_settings.get_boolean (PRIVACY_KEY)) {
            list_box.set_placeholder (empty_alert);
            var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs) {
                list_box.add (new JobRow (printer, job));
            }
        } else {
            list_box.foreach ((row) => {
                list_box.remove (row);
            });
            list_box.set_placeholder (privacy_alert);
        }
    }

    [CCode (instance_pos = -1)]
    private void update_header (JobRow row1, JobRow? row2) {
        if (row1.job.cjob.state == CUPS.IPP.JobState.COMPLETED && (row2 == null || row1.job.cjob.state != row2.job.cjob.state)) {
            var label = new Gtk.Label (_("Completed Jobs"));
            label.xalign = 0;
            label.margin = 3;
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            row1.set_header (label);
        } else {
            row1.set_header (null);
        }
    }
}
