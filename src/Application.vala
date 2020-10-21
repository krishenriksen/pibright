// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2020 Kris Henriksen. (https://www.krishenriksen.dk/)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Kris Henriksen <krishenriksen.work@gmail.com>
 */

using Gtk;
using Cairo;

public class PiBrightAdjustWindow : Gtk.ApplicationWindow {
	private Gdk.Rectangle monitor_dimensions;

	private string css_file;

	private Scale red_slider;
	private Scale green_slider;
	private Scale blue_slider;
	private Scale brightness_slider;	

    public PiBrightAdjustWindow(string css_file, Window main_window) {
    	this.set_title ("Brightness");
    	this.set_keep_above (true);
    	this.set_decorated (false); // No window decoration
		this.set_visual (this.get_screen().get_rgba_visual());
		this.set_type_hint (Gdk.WindowTypeHint.NORMAL);
		this.resizable = false;

		this.css_file = css_file;

        Gdk.Screen default_screen = Gdk.Screen.get_default ();
        monitor_dimensions = default_screen.get_display ().get_primary_monitor ().get_geometry ();		

		this.set_default_size (300, 150);
		this.move(monitor_dimensions.width - 310, 35);

		this.red_slider = new Scale.with_range (Orientation.VERTICAL, 0, 255, 1);
		this.green_slider = new Scale.with_range (Orientation.VERTICAL, 0, 255, 1);
		this.blue_slider = new Scale.with_range (Orientation.VERTICAL, 0, 255, 1);
		this.brightness_slider = new Scale.with_range (Orientation.VERTICAL, 5, 100, 1);
		brightness_slider.inverted = true;

		// container box
		var vbox = new Box (Orientation.HORIZONTAL, 30);
		vbox.get_style_context().add_class ("pibrightadjust");
		vbox.homogeneous = true;
		vbox.add(this.brightness_slider);
		vbox.add(this.red_slider);
		vbox.add(this.green_slider);
		vbox.add(this.blue_slider);
		this.add (vbox);
		this.show_all();

		this.get_css();

		this.brightness_slider.adjustment.value_changed.connect (() => {
			this.write_css();
        });

		this.red_slider.adjustment.value_changed.connect (() => {
			this.write_css();
        });

		this.green_slider.adjustment.value_changed.connect (() => {
			this.write_css();
        });

		this.blue_slider.adjustment.value_changed.connect (() => {
			this.write_css();
        });

		this.focus_out_event.connect(() => { this.destroy(); return true; });
    }

    private void write_css() {
		try {
			string css = ".pibright{background:rgba(" + this.red_slider.adjustment.value.to_string() + "," + this.green_slider.adjustment.value.to_string() + "," + this.blue_slider.adjustment.value.to_string() + "," + (((0 + 100) - this.brightness_slider.adjustment.value) / 100).to_string() + ");}";

			css += "\n.pibrightadjust{padding:20pX;}";

			FileUtils.set_contents (this.css_file, css);
		} catch (Error e) {
			warning ("%s", e.message);
    	}

    	// refresh interface
	    var css_provider = new Gtk.CssProvider ();

	    try {
	        css_provider.load_from_path (this.css_file);
	        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
	    } catch (GLib.Error e) {
	        warning ("Could not load CSS file: %s", this.css_file);
	    }
    }

    private void get_css() {
		string read;

		try {
    		FileUtils.get_contents (this.css_file, out read);
    	} catch (Error e) {
	       	warning ("%s", e.message);
	    }

	    read = read.replace(".pibright{background:rgba(", "");
	    read = read.replace(");}", "");

	    string[] lines = read.split (",");

	    this.red_slider.adjustment.value = double.parse(lines[0]);
	    this.green_slider.adjustment.value = double.parse(lines[1]);
	    this.blue_slider.adjustment.value = double.parse(lines[2]);
	    this.brightness_slider.adjustment.value = (0 + 100 - double.parse(lines[3]) * 100);
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

		if (!this.get_screen ().is_composited()) {
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

    app.activate.connect(() => {
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
