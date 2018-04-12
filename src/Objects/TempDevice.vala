/*-
 * Copyright (c) 2015-2018 elementary LLC. (https://elementary.io)
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

public class Printers.TempDevice : GLib.Object {
    public string device_make_and_model = null;
    public string device_class = null;
    public string device_uri = null;
    public string device_info = null;
    public string device_id = null;
    public TempDevice () {

    }

    public string? get_make_from_id () {
        if (device_id == null)
            return null;

        var attrs = device_id.split (";");
        foreach (var attr in attrs) {
            var keyval = attr.split (":", 2);
            if (keyval.length < 2) {
                continue;
            }

            if (keyval[0] == "MFG") {
                return keyval[1];
            }
        }

        return null;
    }

    public string? get_model_from_id () {
        if (device_id == null)
            return null;

        var attrs = device_id.split (";");
        foreach (var attr in attrs) {
            var keyval = attr.split (":", 2);
            if (keyval.length < 2) {
                continue;
            }

            if (keyval[0] == "MDL") {
                return keyval[1];
            }
        }

        return null;
    }
}
