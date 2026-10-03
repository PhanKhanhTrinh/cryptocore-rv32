proc sim_clear_waves {} {
    set cleared 0

    if {![catch {set waves [get_waves -quiet *]}]} {
        if {[llength $waves] > 0} {
            if {![catch {remove_wave $waves}]} {
                set cleared 1
            }
        } else {
            set cleared 1
        }
    }

    if {!$cleared} {
        catch {remove_wave [get_waves *]}
    }
}

proc sim_has_object {obj_path} {
    if {[catch {set objs [get_objects -quiet $obj_path]}]} {
        return 0
    }
    return [expr {[llength $objs] > 0}]
}

proc sim_add_divider {label} {
    catch {add_wave -divider $label}
}

proc sim_add {obj_path {radix ""}} {
    if {![sim_has_object $obj_path]} {
        puts "Skipping missing waveform object: $obj_path"
        return
    }

    if {$radix eq ""} {
        add_wave $obj_path
    } else {
        add_wave -radix $radix $obj_path
    }
}

proc sim_zoom_fit {} {
    catch {zoom fit}
    catch {zoom_fit}
}
