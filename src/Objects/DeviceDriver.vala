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

public class Printers.DeviceDriver : GLib.Object {
    public string ppd_name = null;
    public string ppd_natural_language = null;
    public string ppd_make = null;
    public string ppd_make_and_model = null;
    public string ppd_device_id = null;
    public string ppd_product = null;
    public string ppd_psversion = null;
    public string ppd_type = null;
    public int ppd_model_number = 0;
    public DeviceDriver () {

    }

    public string? get_model_from_id () {
        if (ppd_device_id == null)
            return null;

        var attrs = ppd_device_id.split (";");
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
