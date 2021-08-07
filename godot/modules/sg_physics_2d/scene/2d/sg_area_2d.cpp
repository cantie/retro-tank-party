/*************************************************************************/
/* Copyright (c) 2021 David Snopek                                       */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "sg_area_2d.h"

#include <core/engine.h>

void SGArea2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_fixed_position"), &SGArea2D::get_fixed_position);
    ClassDB::bind_method(D_METHOD("set_fixed_position", "fixed_position"), &SGArea2D::set_fixed_position);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "fixed_position", PROPERTY_HINT_TYPE_STRING, "SGFixedVector2"), "set_fixed_position", "get_fixed_position");

}

void SGArea2D::_notification(int p_what) {
    /*
    switch (p_what) {
        case NOTIFICATION_TRANSFORM_CHANGED:
            if (Engine::get_singleton()->is_editor_hint() && !updating_position) {
                Transform2D xform = get_transform();
                fixed_position->from_float(xform.get_origin());
            }
            break;
    }
    */
}

void SGArea2D::_changed_callback(Object *p_changed, const char *p_prop) {
    if (!updating_position && strcmp(p_prop, "position") == 0) {
        Transform2D xform = get_transform();
        fixed_position->from_float(xform.get_origin());
    }
}

void SGArea2D::set_fixed_position(const Ref<SGFixedVector2> &p_fixed_position) {
    fixed_position = p_fixed_position;
    updating_position = true;
    set_position(fixed_position->to_float());
    updating_position = false;
}

Ref<SGFixedVector2> SGArea2D::get_fixed_position() {
    return fixed_position;
}

void SGArea2D::sync_to_physics() {

}

bool SGArea2D::overlaps_area() {
    return false;
}

SGArea2D::SGArea2D() 
    : fixed_position(Ref<SGFixedVector2>(memnew(SGFixedVector2))),
      updating_position(false)
{
    if (Engine::get_singleton()->is_editor_hint()) {
        add_change_receptor(this);
    }
}
