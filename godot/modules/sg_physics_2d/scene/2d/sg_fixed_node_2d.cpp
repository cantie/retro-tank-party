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

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "fixed_position", PROPERTY_HINT_TYPE_STRING, "SGFixedVector2"), "set_fixed_position", "get_fixed_position");
}

void SGFixedNode2D::_changed_callback(Object *p_changed, const char *p_prop) {
    if (!updating_position && strcmp(p_prop, "position") == 0) {
        fixed_position->from_float(get_position());
        set_fixed_position(fixed_position);
    }
}

void SGFixedNode2D::_fixed_position_changed() {
    set_fixed_position(fixed_position);
}

void SGFixedNode2D::set_fixed_position(const Ref<SGFixedVector2> &p_fixed_position) {
    fixed_position->set_internal(p_fixed_position->get_internal());
    updating_position = true;
    set_position(fixed_position->to_float());
    updating_position = false;
    _change_notify("fixed_position");
}

Ref<SGFixedVector2> SGFixedNode2D::get_fixed_position() {
    return fixed_position;
}

fixed_vector2 SGFixedNode2D::get_global_fixed_position() const {
    SGFixedNode2D *fixed_parent = dynamic_cast<SGFixedNode2D *>(get_parent());
    if (fixed_parent) {
        return fixed_parent->get_fixed_position()->get_internal() + fixed_position->get_internal();
    }
    return fixed_position->get_internal();
}

SGFixedNode2D::SGFixedNode2D() 
    : fixed_position(Ref<SGFixedVector2>(memnew(SGFixedVector2))),
      updating_position(false)
{
    fixed_position->connect("changed", this, "_fixed_position_changed");

    if (Engine::get_singleton()->is_editor_hint()) {
        add_change_receptor(this);
    }
}
