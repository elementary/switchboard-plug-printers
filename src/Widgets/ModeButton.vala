/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 * Copyright 2008–2013 Christian Hergert <chris@dronelabs.com>,
 * Copyright 2008–2013 Giulio Collura <random.cpp@gmail.com>,
 * Copyright 2008–2013 Victor Eduardo <victoreduardm@gmail.com>,
 * Copyright 2008–2013 ammonkey <am.monkeyd@gmail.com>
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

namespace Printers {

    /**
     * This widget is a multiple option modal switch
     *
     * {{../doc/images/ModeButton.png}}
     */
    public class ModeButton : Gtk.Box {

        private class Item : Gtk.ToggleButton {
            public int index { get; construct; }
            public Item (int index) {
                Object (index: index);
                // add_events (Gdk.EventMask.SCROLL_MASK);
            }
        }

        public signal void mode_added (int index, Gtk.Widget widget);
        public signal void mode_removed (int index, Gtk.Widget widget);
        public signal void mode_changed (Gtk.Widget widget);

        /**
         * Index of currently selected item.
         */
        public int selected {
            get { return _selected; }
            set { set_active (value); }
        }

        /**
         * Read-only length of current ModeButton
         */
        public uint n_items {
            get { return item_map.size; }
        }

        private int _selected = -1;
        private Gee.HashMap<int, Item> item_map;

        /**
         * Makes new ModeButton
         */
        public ModeButton () {

        }

        construct {
            homogeneous = true;
            spacing = 0;

            item_map = new Gee.HashMap<int, Item> ();

            var style = get_style_context ();
            style.add_class (Granite.STYLE_CLASS_LINKED);
            style.add_class ("raised"); // needed for toolbars
        }

        /**
         * Appends text to ModeButton
         *
         * @param text text to append to ModeButton
         * @return index of new item
         */
        public int append_text (string text) {
            return append_widget (new Gtk.Label (text));
        }

        /**
         * Appends given widget to ModeButton
         *
         * @param w widget to add to ModeButton
         * @return index of new item
         */
        public int append_widget (Gtk.Widget w) {
            int index;
            for (index = item_map.size; item_map.has_key (index); index++);
            assert (item_map[index] == null);

            var item = new Item (index);
            var scroll_controller = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.HORIZONTAL);
            scroll_controller.scroll.connect (on_scroll_event);
            item.add_controller (scroll_controller);
            item.child = w;

            item.toggled.connect (() => {
                if (item.active) {
                    selected = item.index;
                } else if (selected == item.index) {
                    // If the selected index still references this item, then it
                    // was toggled by the user, not programmatically.
                    // -> Reactivate the item to prevent an empty selection.
                    item.active = true;
                }
            });

            item_map[index] = item;

            append (item);

            mode_added (index, w);

            return index;
        }

        /**
         * Clear selected items
         */
        private void clear_selected () {
            // Update _selected before deactivating the selected item to let it
            // know that it is being deactivated programmatically, not by the
            // user.
            _selected = -1;

            foreach (var item in item_map.values) {
                if (item != null && item.active) {
                    item.set_active (false);
                }
            }
        }

        /**
         * Sets item of given index's activity
         *
         * @param new_active_index index of changed item
         */
        public void set_active (int new_active_index) {
            if (new_active_index <= -1) {
                clear_selected ();
                return;
            }

            return_if_fail (item_map.has_key (new_active_index));
            var new_item = item_map[new_active_index] as Item;

            if (new_item != null) {
                assert (new_item.index == new_active_index);
                new_item.set_active (true);

                if (_selected == new_active_index) {
                    return;
                }

                // Unselect the previous item
                var old_item = item_map[_selected] as Item;

                // Update _selected before deactivating the selected item to let
                // it know that it is being deactivated programmatically, not by
                // the user.
                _selected = new_active_index;

                if (old_item != null) {
                    old_item.set_active (false);
                }

                mode_changed (new_item.get_child ());
            }
        }

        /**
         * Changes visibility of item of given index
         *
         * @param index index of item to be modified
         * @param val value to change the visiblity to
         */
        public void set_item_visible (int index, bool val) {
            return_if_fail (item_map.has_key (index));
            var item = item_map[index] as Item;

            if (item != null) {
                assert (item.index == index);
                // item.no_show_all = !val;
                item.visible = val;
            }
        }

        /**
         * Removes item at given index
         *
         * @param index index of item to remove
         */
        public new void remove (int index) {
            return_if_fail (item_map.has_key (index));
            var item = item_map[index] as Item;

            if (item != null) {
                assert (item.index == index);
                item_map.unset (index);
                mode_removed (index, item.get_child ());
                item.destroy ();
            }
        }

        /**
         * Clears all children
         */
        public void clear_children () {
            // foreach (weak Gtk.Widget button in get_children ()) {
            //     button.hide ();
            //     if (button.get_parent () != null) {
            //         base.remove (button);
            //     }
            // }
            var children = observe_children ();
            for (var index = 0; index < children.get_n_items (); index++) {
                var button = (Gtk.Widget) children.get_item (index);
                button.hide ();
                if (button.parent != null) {
                    base.remove (button);
                }
            }

            item_map.clear ();

            _selected = -1;
        }

        private bool on_scroll_event (double x, double y) {
            // int offset;

            // switch (ev.direction) {
            //     case Gdk.ScrollDirection.DOWN:
            //     case Gdk.ScrollDirection.RIGHT:
            //         offset = 1;
            //         break;
            //     case Gdk.ScrollDirection.UP:
            //     case Gdk.ScrollDirection.LEFT:
            //         offset = -1;
            //         break;
            //     default:
            //         return false;
            // }

            // Try to find a valid item, since there could be invisible items in
            // the middle and those shouldn't be selected. We use the children list
            // instead of item_map because order matters here.
            var children = observe_children ();
            var n_children = children.get_n_items ();

            var selected_item = item_map[selected];
            if (selected_item == null) {
                return false;
            }

            // int new_item = children.index (selected_item);
            // if (new_item < 0) {
            //     return false;
            // }
            int new_item = 0;
            for (var index = 0; index < children.get_n_items (); index++) {
                if (selected_item == (Item) children.get_item (index)) {
                    new_item = index;
                    break;
                }
            }

            do {
                new_item += (int) y;
                var item = children.get_item (new_item) as Item;

                if (item != null && item.visible && item.sensitive) {
                    selected = item.index;
                    break;
                }
            } while (new_item >= 0 && new_item < n_children);

            return false;
        }
    }
}
