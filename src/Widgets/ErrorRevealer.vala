private class Printers.ErrorRevealer : Gtk.Box {
    public Gtk.Label label_widget { get; construct; }

    public string label { get; construct set; }
    public bool reveal_child { get; set; default = false; }

    public ErrorRevealer (string label) {
        Object (label: label);
    }

    construct {
        label_widget = new Gtk.Label ("") {
            justify = RIGHT,
            max_width_chars = 55,
            use_markup = true,
            wrap = true,
            xalign = 1
        };
        label_widget.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var revealer = new Gtk.Revealer () {
            child = label_widget,
            transition_type = CROSSFADE,
            halign = END,
            hexpand = true
        };

        bind_property ("reveal-child", revealer, "reveal-child", SYNC_CREATE);
        bind_property ("label", label_widget, "label", SYNC_CREATE);

        append (revealer);
    }
}
