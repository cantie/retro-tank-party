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

#include "sg_kinematic_body_2d.h"

#include "../../internal/sg_bodies_2d_internal.h"

void SGKinematicBody2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("move_and_collide", "linear_velocity"), &SGKinematicBody2D::move_and_collide);
    ClassDB::bind_method(D_METHOD("move_and_slide", "linear_velocity"), &SGKinematicBody2D::move_and_slide);
}

bool SGKinematicBody2D::move_and_collide(const Ref<SGFixedVector2> &linear_velocity) {
    // @todo actually implement this!
    return false;
}

Ref<SGFixedVector2> SGKinematicBody2D::move_and_slide(const Ref<SGFixedVector2> &linear_velocity) {
    Ref<SGFixedVector2> result = Ref<SGFixedVector2>(memnew(SGFixedVector2));

    // Temp: Just move it for now.
    get_fixed_position()->iadd(linear_velocity);
    sync_to_physics_engine();

    return result;
}

SGKinematicBody2D::SGKinematicBody2D()
    : SGCollisionObject2D(memnew(SGBody2DInternal(SGBody2DInternal::BodyType::BODY_KINEMATIC)))
{
}

SGKinematicBody2D::~SGKinematicBody2D() {
}
