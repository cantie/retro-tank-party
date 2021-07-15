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

#include "register_types.h"

#include <core/class_db.h>
#include <core/engine.h>

#include "./math/fixed_singleton.h"
#include "./math/fixed_vector2.h"
#include "./scene/2d/sg_area_2d.h"
#include "./scene/2d/sg_collision_shape_2d.h"
#include "./scene/resources/sg_shapes_2d.h"

#include "./editor/sg_fixed_math_editor_plugin.h"

static Fixed *fixed_singleton;

void register_sg_physics_2d_types() {
    ClassDB::register_class<Fixed>();
    ClassDB::register_class<FixedVector2>();

    ClassDB::register_class<SGCollisionShape2D>();

    ClassDB::register_class<SGArea2D>();

    ClassDB::register_virtual_class<SGShape2D>();
    ClassDB::register_class<SGRectangleShape2D>();

    fixed_singleton = memnew(Fixed);
    Engine::get_singleton()->add_singleton(Engine::Singleton("Fixed", Fixed::get_singleton()));

#if TOOLS_ENABLED
    EditorPlugins::add_by_type<SGFixedMathEditorPlugin>();
#endif
}

void unregister_sg_physics_2d_types() {
    memdelete(fixed_singleton);
}
