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

#include "sg_collision_shape_2d.h"

#include <core/engine.h>

void SGCollisionShape2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_shape", "shape"), &SGCollisionShape2D::set_shape);
	ClassDB::bind_method(D_METHOD("get_shape"), &SGCollisionShape2D::get_shape);

	ClassDB::bind_method(D_METHOD("_shape_changed"), &SGCollisionShape2D::_shape_changed);

    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "shape", PROPERTY_HINT_RESOURCE_TYPE, "SGShape2D"), "set_shape", "get_shape");
}

void SGCollisionShape2D::_notification(int p_what) {
    switch (p_what) {
        case NOTIFICATION_DRAW:
            if (!Engine::get_singleton()->is_editor_hint() && !get_tree()->is_debugging_collisions_hint()) {
                return;
            }

            if (shape.is_valid()) {
                shape->draw(get_canvas_item(), Color(0.9f, 0.7f, 0.7f));
            }

            break;
        
        case NOTIFICATION_PARENTED:
            collision_object = Object::cast_to<SGCollisionObject2D>(get_parent());
            if (collision_object && shape.is_valid()) {
                collision_object->add_shape(shape->get_shape_internal());
            }
            break;
        
        case NOTIFICATION_UNPARENTED:
            if (collision_object && shape.is_valid()) {
                collision_object->remove_shape(shape->get_shape_internal());
            }
            collision_object = nullptr;
            break;

    }
}

void SGCollisionShape2D::set_shape(const Ref<SGShape2D> &p_shape) {
    if (shape.is_valid()) {
        shape->disconnect("changed", this, "_shape_changed");
        if (collision_object) {
            collision_object->remove_shape(p_shape->get_shape_internal());
        }
    }

    shape = p_shape;

    if (shape.is_valid()) {
        shape->connect("changed", this, "_shape_changed");
        if (collision_object) {
            collision_object->add_shape(shape->get_shape_internal());
        }
    }

    update();
}

Ref<SGShape2D> SGCollisionShape2D::get_shape() {
    return shape;
}

void SGCollisionShape2D::_shape_changed() {
    update();
}

SGCollisionShape2D::SGCollisionShape2D() {
    collision_object = nullptr;
}

SGCollisionShape2D::~SGCollisionShape2D() {
}
