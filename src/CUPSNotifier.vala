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

[DBus (name = "org.cups.cupsd.Notifier")]
public interface Cups.NotifierDBus : Object {
    // The properties aren't sent so we need to connect to them ourself
}

public class Cups.Notifier : Object {
    private static Cups.Notifier notifier = null;
    public static unowned Cups.Notifier get_default () {
        if (notifier == null) {
            notifier = new Notifier ();
        }

        return notifier;
    }

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

    private NotifierDBus dbus_notifier;
    private Notifier () {
        Bus.get_proxy.begin<NotifierDBus> (BusType.SYSTEM, "org.cups.cupsd.Notifier", "/org/cups/cupsd/Notifier", GLib.DBusProxyFlags.NONE, null, (obj, res) => {
            try {
                dbus_notifier = Bus.get_proxy.end (res);
                ((GLib.DBusProxy) dbus_notifier).g_connection.signal_subscribe (null, "org.cups.cupsd.Notifier", null, "/org/cups/cupsd/Notifier", null, GLib.DBusSignalFlags.NONE, subscription_callback);
            } catch (IOError e) {
                critical (e.message);
            }
        });
    }

    private void subscription_callback (DBusConnection connection, string sender_name, string object_path, string interface_name, string signal_name, Variant parameters) {
        switch (parameters.n_children ()) {
            case 1:
                send_server_event (signal_name, parameters);
                break;
            case 6:
                send_printer_event (signal_name, parameters);
                break;
            case 11:
                send_job_event (signal_name, parameters);
                break;
            default:
                debug ("Signal `%s` isn't handled by the plug", signal_name);
                break;
        }
    }

    private void send_server_event (string signal_name, Variant parameters) {
        var text = parameters.get_child_value (0).get_string ();
        switch (signal_name) {
            case "ServerRestarted":
                server_restarted (text);
                break;
            case "ServerStarted":
                server_started (text);
                break;
            case "ServerStopped":
                server_stopped (text);
                break;
            case "ServerAudit":
                server_audit (text);
                break;
            default:
                debug ("Signal `%s` isn't handled by the plug", signal_name);
                break;
        }
    }

    private void send_printer_event (string signal_name, Variant parameters) {
        var text = parameters.get_child_value (0).get_string ();
        var printer_uri = parameters.get_child_value (1).get_string ();
        var name = parameters.get_child_value (2).get_string ();
        var state = parameters.get_child_value (3).get_uint32 ();
        var state_reasons = parameters.get_child_value (4).get_string ();
        var is_accepting_jobs = parameters.get_child_value (5).get_boolean ();
        switch (signal_name) {
            case "PrinterRestarted":
                printer_restarted (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterShutdown":
                printer_shutdown (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterStopped":
                printer_stopped (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterStateChanged":
                printer_state_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterFinishingsChanged":
                printer_finishings_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterMediaChanged":
                printer_media_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterAdded":
                printer_added (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterDeleted":
                printer_deleted (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            case "PrinterModified":
                printer_modified (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
                break;
            default:
                debug ("Signal `%s` isn't handled by the plug", signal_name);
                break;
        }
    }

    private void send_job_event (string signal_name, Variant parameters) {
        var text = parameters.get_child_value (0).get_string ();
        var printer_uri = parameters.get_child_value (1).get_string ();
        var name = parameters.get_child_value (2).get_string ();
        var state = parameters.get_child_value (3).get_uint32 ();
        var state_reasons = parameters.get_child_value (4).get_string ();
        var is_accepting_jobs = parameters.get_child_value (5).get_boolean ();
        var job_id = parameters.get_child_value (6).get_uint32 ();
        var job_state = parameters.get_child_value (7).get_uint32 ();
        var job_state_reason = parameters.get_child_value (8).get_string ();
        var job_name = parameters.get_child_value (9).get_string ();
        var job_impressions_completed = parameters.get_child_value (10).get_uint32 ();
        switch (signal_name) {
            case "JobCreated":
                job_created (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            case "JobCompleted":
                job_completed (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            case "JobStopped":
                job_stopped (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            case "JobConfigChanged":
                job_config_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            case "JobProgress":
                job_progress (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            case "JobState":
                this.job_state (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            case "JobStateChanged":
                job_state_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed);
                break;
            default:
                debug ("Signal `%s` isn't handled by the plug", signal_name);
                break;
        }
    }
}
