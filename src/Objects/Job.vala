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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.Job : GLib.Object {
    public unowned CUPS.Job cjob;
    public signal void stopped ();
    public signal void completed ();
    public signal void state_changed ();

    private Printer printer;
    private int uid;

    public Job (CUPS.Job cjob, Printer printer) {
        this.cjob = cjob;
        this.printer = printer;
        uid = cjob.id;
        unowned Cups.Notifier notifier = Cups.get_notifier ();
        if (cjob.state != CUPS.IPP.JobState.CANCELED && cjob.state != CUPS.IPP.JobState.ABORTED && cjob.state != CUPS.IPP.JobState.COMPLETED) {
            notifier.job_completed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
                if (job_id == uid) {
                    completed ();
                }
            });

            notifier.job_stopped.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
                if (job_id == uid) {
                    stopped ();
                }
            });

            notifier.job_state_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
                if (job_id == uid) {
                    state_changed ();
                }
            });
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

    public DateTime get_used_time () {
        if (cjob.completed_time != 0) {
            return new DateTime.from_unix_local (cjob.completed_time);
        } else if (cjob.processing_time != 0) {
            return new DateTime.from_unix_local (cjob.processing_time);
        } else {
            return new DateTime.from_unix_local (cjob.creation_time);
        }
    }

    public string translated_job_state () {
        switch (cjob.state) {
            case CUPS.IPP.JobState.PENDING:
                return _("Job Pending");
            case CUPS.IPP.JobState.HELD:
                return _("On Held");
            case CUPS.IPP.JobState.PROCESSING:
                return _("Processing…");
            case CUPS.IPP.JobState.STOPPED:
                return _("Job Stopped");
            case CUPS.IPP.JobState.CANCELED:
                return _("Job Canceled");
            case CUPS.IPP.JobState.ABORTED:
                return _("Job Aborded");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return _("Job Completed");
        }
    }

    public GLib.Icon? state_icon () {
        switch (cjob.state) {
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
}
