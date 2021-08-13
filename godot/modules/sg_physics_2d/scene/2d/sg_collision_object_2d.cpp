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

#include "sg_collision_object_2d.h"

#include <core/engine.h>

#include "sg_collision_shape_2d.h"

void SGCollisionObject2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("sync_to_physics_engine"), &SGCollisionObject2D::sync_to_physics_engine);
}

String SGCollisionObject2D::get_configuration_warning() const {
    String warning = SGFixedNode2D::get_configuration_warning();

    bool has_shape_child = false;
    for (int i = 0; i < get_child_count(); i++) {
        if (Object::cast_to<SGCollisionShape2D>(get_child(i))) {
            has_shape_child = true;
            break;
        }
    }
    if (!has_shape_child) {
        if (warning != String()) {
            warning += "\n\n";
        }
        warning += TTR("This node needs at least one SGCollisionShape2D as a child.");
    }

    return warning;
}

void SGCollisionObject2D::sync_to_physics_engine() const {
    // @todo loop over children, find SGCollisionShape2D objects and call sync_to_physics_engin()
}

SGCollisionObject2D::SGCollisionObject2D() {
}
