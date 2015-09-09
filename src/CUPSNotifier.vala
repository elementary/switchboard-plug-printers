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

[DBus (name = "org.cups.cupsd.Notifier")]
interface CUPSNotifier : Object {
    public signal void server_restarted (string text);
    public signal void server_started (string text);
    public signal void server_stopped (string text);
    public signal void server_audit (string text);

    public signal void printer_restarted (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_shutdown (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_stopped (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_state_changed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_finishings_changed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_media_changed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_added (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_deleted (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);
    public signal void printer_modified (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs);

    public signal void job_created (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
    public signal void job_completed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
    public signal void job_stopped (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
    public signal void job_config_changed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
    public signal void job_progress (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
    public signal void job_state (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
    public signal void job_state_changed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs, uint32 job_id, uint32 job_state, string job_state_reason, string job_name, uint32 job_impressions_completed);
}
