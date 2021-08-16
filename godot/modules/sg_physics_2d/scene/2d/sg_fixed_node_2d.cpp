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

#include "sg_fixed_node_2d.h"

#include <core/engine.h>

void SGFixedNode2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_fixed_position"), &SGFixedNode2D::get_fixed_position);
    ClassDB::bind_method(D_METHOD("set_fixed_position", "fixed_position"), &SGFixedNode2D::set_fixed_position);
    ClassDB::bind_method(D_METHOD("_fixed_position_changed"), &SGFixedNode2D::_fixed_position_changed);

    ClassDB::bind_method(D_METHOD("get_fixed_scale"), &SGFixedNode2D::get_fixed_scale);
    ClassDB::bind_method(D_METHOD("set_fixed_scale", "fixed_scale"), &SGFixedNode2D::set_fixed_scale);
    ClassDB::bind_method(D_METHOD("_fixed_scale_changed"), &SGFixedNode2D::_fixed_scale_changed);

    ClassDB::bind_method(D_METHOD("get_fixed_rotation"), &SGFixedNode2D::get_fixed_rotation);
    ClassDB::bind_method(D_METHOD("set_fixed_rotation", "fixed_scale"), &SGFixedNode2D::set_fixed_rotation);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "fixed_position", PROPERTY_HINT_TYPE_STRING, "SGFixedVector2"), "set_fixed_position", "get_fixed_position");
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "fixed_scale", PROPERTY_HINT_TYPE_STRING, "SGFixedVector2"), "set_fixed_scale", "get_fixed_scale");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "fixed_rotation"), "set_fixed_rotation", "get_fixed_rotation");
}

void SGFixedNode2D::_changed_callback(Object *p_changed, const char *p_prop) {
    if (!updating_transform) {
        if (strcmp(p_prop, "position") == 0) {
            fixed_position->from_float(get_position());
            set_fixed_position(fixed_position);
        }
        else if (strcmp(p_prop, "scale") == 0) {
            fixed_scale->from_float(get_scale());
            set_fixed_scale(fixed_scale);
        }
        else if (strcmp(p_prop, "rotation") == 0) {
            fixed_rotation = fixed::from_float(get_rotation()).value;
            set_fixed_rotation(fixed_rotation);
        }
    }
}

fixed_vector2 SGFixedNode2D::get_global_fixed_position() const {
    SGFixedNode2D *fixed_parent = dynamic_cast<SGFixedNode2D *>(get_parent());
    if (fixed_parent) {
        return fixed_parent->get_fixed_position()->get_internal() + fixed_position->get_internal();
    }
    return fixed_position->get_internal();
}

void SGFixedNode2D::_fixed_position_changed() {
    set_fixed_position(fixed_position);
}

void SGFixedNode2D::_fixed_scale_changed() {
    set_fixed_scale(fixed_scale);
}

void SGFixedNode2D::set_fixed_position(const Ref<SGFixedVector2> &p_fixed_position) {
    fixed_position->set_internal(p_fixed_position->get_internal());
    updating_transform = true;
    set_position(fixed_position->to_float());
    fixed_transform[2] = fixed_position->get_internal();
    updating_transform = false;
    _change_notify("fixed_position");
}

Ref<SGFixedVector2> SGFixedNode2D::get_fixed_position() {
    return fixed_position;
}

void SGFixedNode2D::set_fixed_scale(const Ref<SGFixedVector2> &p_fixed_scale) {
    fixed_scale->set_internal(p_fixed_scale->get_internal());
    updating_transform = true;
    set_scale(fixed_scale->to_float());
    updating_transform = false;
    _change_notify("fixed_scale");
}

Ref<SGFixedVector2> SGFixedNode2D::get_fixed_scale() {
    return fixed_scale;
}

void SGFixedNode2D::set_fixed_rotation(int p_fixed_rotation) {
    fixed_rotation = p_fixed_rotation;
    updating_transform = true;
    set_rotation(fixed(p_fixed_rotation).to_float());
    updating_transform = false;
    _change_notify("fixed_rotation");
}

int SGFixedNode2D::get_fixed_rotation() const {
    return fixed_rotation;
}

SGFixedNode2D::SGFixedNode2D() {
    fixed_position = Ref<SGFixedVector2>(memnew(SGFixedVector2));
    fixed_position->connect("changed", this, "_fixed_position_changed");

    fixed_scale = Ref<SGFixedVector2>(memnew(SGFixedVector2));
    fixed_scale->connect("changed", this, "_fixed_scale_changed");

    fixed_rotation = 0;

    updating_transform = false;


    if (Engine::get_singleton()->is_editor_hint()) {
        add_change_receptor(this);
    }
}

SGFixedNode2D::~SGFixedNode2D() {
}
