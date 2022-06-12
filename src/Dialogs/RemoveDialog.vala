/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 */

public class Printers.RemoveDialog : Granite.MessageDialog {
    public Printer printer { get; construct; }

    public RemoveDialog (Printer printer) {
        Object (
            buttons: Gtk.ButtonsType.CANCEL,
            image_icon: new ThemedIcon ("dialog-question"),
            modal: true,
            printer: printer,
            primary_text: _("Are You Sure You Want To Remove '%s'?").printf (printer.info),
            secondary_text: _("By removing '%s' you'll lose all print history and configuration associated with it.").printf (printer.info)
        );
    }

    construct {
        var button = add_button (_("Remove"), 0);
        button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        response.connect (on_response);
    }

    private void on_response (Gtk.Dialog source, int response_id) {
        if (response_id == 0) {
            try {
                Cups.get_pk_helper ().printer_delete (printer.dest.name);
            } catch (Error e) {
                critical (e.message);
            }
        }
        destroy ();
    }
}
