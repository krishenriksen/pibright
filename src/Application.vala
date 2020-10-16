/*
* Copyright (c) 2011-2020 PiBright
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Kris Henriksen <krishenriksen.work@gmail.com>
*/

using Gtk;
using Cairo;

public class PiBrightAdjustWindow : Gtk.ApplicationWindow {
	private Gdk.Rectangle monitor_dimensions;

    public PiBrightAdjustWindow(string css_file, Window main_window) {
    	this.set_title ("Brightness");
    	this.set_keep_above (true);
    	this.set_decorated (false); // No window decoration
		this.set_visual (this.get_screen().get_rgba_visual());
		this.set_type_hint (Gdk.WindowTypeHint.NORMAL);
		this.resizable = false;

        Gdk.Screen default_screen = Gdk.Screen.get_default ();
        monitor_dimensions = default_screen.get_display ().get_primary_monitor ().get_geometry ();		

		this.set_default_size (200, 50);
		this.move(monitor_dimensions.width - 210, 30);

		string read;
		try {
    		FileUtils.get_contents (css_file, out read);
    	} catch (Error e) {
	       	stderr.printf ("%s\n", e.message);
	    }

		string[] lines = read.split (",");

		double opacity = (0 + 100 - (double.parse(lines[3].replace(");}", "")) * 100));

		var slider = new Scale.with_range (Orientation.HORIZONTAL, 0, 100, 1);
		slider.adjustment.value = opacity;

		slider.adjustment.value_changed.connect (() => {
			double reverse = (0 + 100 - slider.adjustment.value) / 100;

			try {
				FileUtils.set_contents (css_file, ".pibright{background:rgba(0, 0, 0, " + reverse.to_string() + ");}");
			} catch (Error e) {
	        	stderr.printf ("%s\n", e.message);
	    	}				

		    var css_provider = new Gtk.CssProvider ();

		    try {
		        css_provider.load_from_path (css_file);
		        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		    } catch (GLib.Error e) {
		        warning ("Could not load CSS file: %s", css_file);
		    }
        });

		this.add(slider);

		this.show_all();

		this.focus_out_event.connect ( () => { this.destroy(); return true; } );
    }

    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_name (event.keyval)) {
            case "Escape": {
            	this.destroy ();

                return true;
            }
		}

        base.key_press_event (event);
        return false;
	}

    private new void destroy () {
        base.destroy();
        Gtk.main_quit();
    }
}

public class PiBrightWindow : Gtk.ApplicationWindow {
	private Gdk.Rectangle monitor_dimensions;

    public PiBrightWindow() {
		this.set_keep_above (true);
		this.set_skip_taskbar_hint (true); // Don't display the window in the task bar
		this.set_decorated (false); // No window decoration
		this.set_visual (this.get_screen().get_rgba_visual());
		this.set_type_hint (Gdk.WindowTypeHint.DESKTOP);
		this.resizable = false;

        Gdk.Screen default_screen = Gdk.Screen.get_default ();
        monitor_dimensions = default_screen.get_display ().get_primary_monitor ().get_geometry ();

		this.set_default_size (monitor_dimensions.width, monitor_dimensions.height);
		this.move(0, 0);

		this.draw.connect (on_window_draw);
    }

	[GtkCallback]
	private bool on_window_draw (Widget widget, Context ctx) {
		widget.get_style_context().add_class ("pibright");

		update_input_shape();

		return false;
	}

	private void update_input_shape () {
		var window_region = this.create_region_from_widget (this.get_toplevel ());
		var brightness_view_region = this.create_region_from_widget (this);
		window_region.subtract (brightness_view_region);

		this.input_shape_combine_region (window_region);

		if (!this.get_screen ().is_composited ()) {
			base.destroy();
			Gtk.main_quit();
		}
	}

	private Region create_region_from_widget (Widget widget) {
		var rectangle = Cairo.RectangleInt () {
			width = widget.get_allocated_width (),
			height = widget.get_allocated_height ()
		};

		widget.translate_coordinates (widget.get_toplevel (), 0, 0, out rectangle.x, out rectangle.y);
		var region = new Region.rectangle (rectangle);

		return region;
	}
}

static int main (string[] args) {
    Gtk.init (ref args);
    Gtk.Application app = new Gtk.Application ("com.github.krishenriksen.pibright", GLib.ApplicationFlags.FLAGS_NONE);

    string css_file = Config.PACKAGE_SHAREDIR +
        "/" + Config.PROJECT_NAME +
        "/" + "pibright.css";
    var css_provider = new Gtk.CssProvider ();

    try {
        css_provider.load_from_path (css_file);
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    } catch (GLib.Error e) {
        warning ("Could not load CSS file: %s", css_file);
    }

    app.activate.connect( () => {
    	var main_window = new PiBrightWindow();

        if (app.get_windows ().length () == 0) {
			main_window.set_application (app);
			main_window.show();
			main_window.destroy.connect (Gtk.main_quit);
        }
        else {
    		var adjust_window = new PiBrightAdjustWindow(css_file, main_window);
			adjust_window.set_application (app);
			adjust_window.show();
        }

        Gtk.main ();
    });
    app.run (args);
	
	return 1;
}
