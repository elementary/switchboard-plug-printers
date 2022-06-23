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

public class Printers.Job : GLib.Object {
    public signal void state_changed ();

    public unowned Printer printer { get; construct; }
    public int uid { get; construct; }
    public CUPS.IPP.JobState state { get; set construct; }
    public string title { get; construct; }
    public string format { get; construct; }
    public string reasons { get; set; default = "None"; }
    public DateTime creation_time { get; construct; }
    public DateTime? completed_time { get; set; default = null; }

    public Job (CUPS.Job cjob, Printer printer) {
        Object (
            creation_time: cjob.creation_time > 0 ? new DateTime.from_unix_local (cjob.creation_time) : new DateTime.now (),
            completed_time: cjob.completed_time > 0 ? new DateTime.from_unix_local (cjob.completed_time) : null,
            state: cjob.state,
            title: cjob.title,
            printer: printer,
            format: cjob.format,
            uid: cjob.id
        );

        unowned Cups.Notifier notifier = Cups.Notifier.get_default ();
        if (state != CUPS.IPP.JobState.CANCELED &&
            state != CUPS.IPP.JobState.ABORTED &&
            state != CUPS.IPP.JobState.COMPLETED) {

            notifier.job_progress.connect (on_job_state_changed);
            notifier.job_completed.connect (on_job_state_changed);
            notifier.job_state_changed.connect (on_job_state_changed);
        }
    }

    private void on_job_state_changed (
        string text, string printer_uri, string name, uint32 printer_state, string state_reasons, bool is_accepting_jobs,
        uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed) {
        if (job_id == uid) {
            state = (CUPS.IPP.JobState)job_state;
            if (state == CUPS.IPP.JobState.COMPLETED &&
                completed_time == null) {

                completed_time = new DateTime.now ();
            }

            state_changed ();
        }
    }

    public void pause () {
        try {
            Cups.get_pk_helper ().job_set_hold_until (uid, "indefinite");
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void stop () {
        try {
            Cups.get_pk_helper ().job_cancel_purge (uid, false);
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void resume () {
        try {
            Cups.get_pk_helper ().job_set_hold_until (uid, "no-hold");
        } catch (Error e) {
            critical (e.message);
        }
    }

    public DateTime? get_display_time () {
        switch (state) {
            case CUPS.IPP.JobState.CANCELED:
            case CUPS.IPP.JobState.ABORTED:
                return null;
            case CUPS.IPP.JobState.COMPLETED:
                return completed_time;
            case CUPS.IPP.JobState.STOPPED:
            case CUPS.IPP.JobState.PENDING:
            case CUPS.IPP.JobState.PROCESSING:
            case CUPS.IPP.JobState.HELD:
                break;
        }

        return creation_time;
    }

    public bool is_ongoing {
        get {
            switch (state) {
                case CUPS.IPP.JobState.PENDING:
                case CUPS.IPP.JobState.HELD:
                case CUPS.IPP.JobState.PROCESSING:
                case CUPS.IPP.JobState.STOPPED:
                    return true;
                case CUPS.IPP.JobState.CANCELED:
                case CUPS.IPP.JobState.ABORTED:
                case CUPS.IPP.JobState.COMPLETED:
                    return false;
            }

            assert_not_reached ();
        }
    }

    public string translated_job_state () {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
                return C_("Print Job", "Pending");
            case CUPS.IPP.JobState.HELD:
                return C_("Print Job", "On Hold");
            case CUPS.IPP.JobState.PROCESSING:
                return C_("Print Job", "In Progress");
            case CUPS.IPP.JobState.STOPPED:
                return C_("Print Job", "Stopped");
            case CUPS.IPP.JobState.CANCELED:
                return C_("Print Job", "Canceled");
            case CUPS.IPP.JobState.ABORTED:
                return C_("Print Job", "Aborted");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return C_("Print Job", "Completed");
        }
    }

    public GLib.Icon? state_icon () {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
            case CUPS.IPP.JobState.PROCESSING:
            case CUPS.IPP.JobState.HELD:
                return new ThemedIcon ("media-playback-pause");
            case CUPS.IPP.JobState.STOPPED:
                return new ThemedIcon ("media-playback-stop");
            case CUPS.IPP.JobState.CANCELED:
            case CUPS.IPP.JobState.ABORTED:
                return new ThemedIcon ("process-error");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return new ThemedIcon ("process-completed");
        }
    }

    public GLib.Icon get_file_icon () {
        if (".png" in title || ".jpg" in title || ".jpeg" in title || ".bmp" in title) {
            return new ThemedIcon ("image-x-generic");
        } else if (".xcf" in title) {
            return new ThemedIcon ("image-x-xcf");
        } else if (".svg" in title) {
            return new ThemedIcon ("image-x-svg+xml");
        } else if (".pdf" in title) {
            return new ThemedIcon ("application-pdf");
        }

        return new ThemedIcon (format.replace ("/", "-"));
    }
}
