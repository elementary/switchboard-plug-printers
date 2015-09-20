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

    public Job (CUPS.Job cjob) {
        this.cjob = cjob;
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
