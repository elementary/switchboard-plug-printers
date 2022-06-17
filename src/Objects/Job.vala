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

public class Printers.Job : GLib.Object {
    // public unowned CUPS.Job cjob;
    public signal void state_changed ();

    public unowned Printer printer { get; construct; }
    public int uid { get; construct; }
    public CUPS.IPP.JobState state { get; set construct; }
    public string title { get; construct; }
    public string format { get; construct; }
    public DateTime creation_time { get; construct; }
    public DateTime? completed_time { get; set; default = null; }
    public DateTime? start_time { get; set; default = null; }

    public Job (CUPS.Job cjob, Printer printer) {
        Object (
            creation_time: new DateTime.from_unix_local (cjob.creation_time),
            start_time: new DateTime.from_unix_local (cjob.processing_time),
            completed_time: new DateTime.from_unix_local (cjob.completed_time),
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
warning ("job state changed %s", state.to_string ());
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

    public DateTime get_display_time () {
        if (completed_time != null) {
            return completed_time;
        } else if (start_time != null) {
            return start_time;
        } else {
            return creation_time;
        }
    }

    public string translated_job_state () {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
                return _("Job Pending");
            case CUPS.IPP.JobState.HELD:
                return _("On Hold");
            case CUPS.IPP.JobState.PROCESSING:
                return _("Processing…");
            case CUPS.IPP.JobState.STOPPED:
                return _("Job Stopped");
            case CUPS.IPP.JobState.CANCELED:
                return _("Job Canceled");
            case CUPS.IPP.JobState.ABORTED:
                return _("Job Aborted");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return _("Job Completed");
        }
    }

    public GLib.Icon? state_icon () {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
            case CUPS.IPP.JobState.PROCESSING:
                return null;
            case CUPS.IPP.JobState.HELD:
            case CUPS.IPP.JobState.STOPPED:
                return new ThemedIcon ("media-playback-pause");
            case CUPS.IPP.JobState.CANCELED:
            case CUPS.IPP.JobState.ABORTED:
                return new ThemedIcon ("process-error-symbolic");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return new ThemedIcon ("process-completed-symbolic");
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

    public string get_hold_until () {
        char[] job_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, job_uri, "ipp", null, "localhost", 0, "/jobs/%d", uid);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_JOB_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "job-uri", null, (string)job_uri);

        string[] attributes = { "job-hold-until" };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute ("job-hold-until", CUPS.IPP.Tag.ZERO);
            return attr.get_string ();
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return "no-hold";
        }
    }
}
