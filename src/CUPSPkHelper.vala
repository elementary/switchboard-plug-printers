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

[DBus (name = "org.opensuse.CupsPkHelper.Mechanism")]
public interface Cups.PkHelper : Object {
    public abstract string file_get (string resource, string filename) throws Error;
    public abstract string file_put (string resource, string filename) throws Error;
    public abstract void server_get_settings (out string error, out GLib.HashTable<string, string> settings) throws Error;
    public abstract string server_set_settings (GLib.HashTable<string, string> settings) throws Error;
    public abstract void devices_get (int timeout, int limit, string[] include_schemes, string[] exclude_schemes, out string error, out GLib.HashTable<string, string> devices) throws Error;

    public abstract string printer_add (string name, string uri, string ppd, string info, string location) throws Error;
    public abstract string printer_add_with_ppd_file (string name, string uri, string ppd, string info, string location) throws Error;
    public abstract string printer_set_device (string name, string device) throws Error;
    public abstract string printer_set_default (string name) throws Error;
    public abstract string printer_set_enabled (string name, bool enabled) throws Error;
    public abstract string printer_set_accept_jobs (string name, bool enabled, string reason = "") throws Error;
    public abstract string printer_delete (string name) throws Error;

    public abstract string class_add_printer (string name, string printer) throws Error;
    public abstract string class_delete_printer (string name, string printer) throws Error;
    public abstract string class_delete (string name) throws Error;

    public abstract string printer_set_info (string name, string info) throws Error;
    public abstract string printer_set_location (string name, string location) throws Error;
    public abstract string printer_set_shared (string name, bool shared) throws Error;
    public abstract string printer_set_job_sheets (string name, string start, string end) throws Error;
    public abstract string printer_set_error_policy (string name, string policy) throws Error;
    public abstract string printer_set_op_policy (string name, string policy) throws Error;
    public abstract string printer_set_users_allowed (string name, string[] users) throws Error;
    public abstract string printer_set_users_denied (string name, string[] users) throws Error;
    public abstract string printer_add_option_default (string name, string option, string[] values) throws Error;
    public abstract string printer_delete_option_default (string name, string option) throws Error;
    public abstract string printer_add_option (string name, string option, string[] values) throws Error;

    public abstract string job_cancel_purge (int jobid, bool purge) throws Error;
    public abstract string job_restart (int jobid) throws Error;
    public abstract string job_set_hold_until (int jobid, string job_hold_until) throws Error;
}
