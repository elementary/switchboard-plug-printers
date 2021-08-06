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
                ((GLib.DBusProxy) dbus_notifier).g_connection.signal_subscribe (null, "org.cups.cupsd.Notifier", null, "/org/cups/cupsd/Notifier", null, GLib.DBusSignalFlags.NONE, (GLib.DBusSignalCallback)subscription_callback);
                //when signal subscribe found properties it will register dbus_notifier

                 dbus_notifier.server_restarted.connect ((text) => server_restarted (text));
                 dbus_notifier.server_started.connect ((text) => server_started (text));
                 dbus_notifier.server_stopped.connect ((text) => server_stopped (text));
                 dbus_notifier.server_audit.connect ((text) => server_audit (text));

                 dbus_notifier.printer_restarted.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_restarted (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_shutdown.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_shutdown (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_stopped.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_stopped (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_state_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_state_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_finishings_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_finishings_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_media_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_media_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_added.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_added (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_deleted.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_deleted (text, printer_uri, name, state, state_reasons, is_accepting_jobs));
                 dbus_notifier.printer_modified.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => printer_modified (text, printer_uri, name, state, state_reasons, is_accepting_jobs));

                 dbus_notifier.job_created.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => job_created (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
                 dbus_notifier.job_completed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => job_completed (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
                 dbus_notifier.job_stopped.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => job_stopped (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
                 dbus_notifier.job_config_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => job_config_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
                 dbus_notifier.job_progress.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => job_progress (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
                 dbus_notifier.job_state.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => this.job_state (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
                 dbus_notifier.job_state_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => job_state_changed (text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed));
            } catch (IOError e) {
                critical (e.message);
            }
        });
    }

    private void subscription_callback (DBusConnection connection, string? sender_name, string object_path, string interface_name, string signal_name, Variant parameters) {}
}
