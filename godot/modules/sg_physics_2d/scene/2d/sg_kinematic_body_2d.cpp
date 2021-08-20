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
#include "../../internal/sg_world_2d_internal.h"

void SGKinematicBody2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("move_and_collide", "linear_velocity"), &SGKinematicBody2D::move_and_collide);
    ClassDB::bind_method(D_METHOD("move_and_slide", "linear_velocity"), &SGKinematicBody2D::move_and_slide);
}

bool SGKinematicBody2D::move_and_collide(const Ref<SGFixedVector2> &linear_velocity) {
    SGWorld2DInternal *world = SGWorld2DInternal::get_singleton();

    List<SGBody2DInternal *> *overlapping_bodies;

    // Move the body the full amount.
    fixed_transform2d original_transform = internal->get_transform();
    fixed_transform2d test_transform = original_transform;
    test_transform.set_origin(original_transform.get_origin() + linear_velocity->get_internal());
    internal->set_transform(test_transform);

    // Check if we're colliding. If not, sync from physics engine and bail.
    overlapping_bodies = world->get_overlapping_bodies(internal);
    if (overlapping_bodies->size() == 0) {
        memdelete(overlapping_bodies);
        _set_fixed_position(test_transform.get_origin());
        return false;
    }
    
    List<SGBody2DInternal *> *last_overlapping_bodies = overlapping_bodies;

    // Use binary search to find the point at which we collide, and the point just before that.
    fixed low = fixed::ZERO;
    fixed hi = fixed::ONE;
    for (int i = 0; i < 8; i++) {
        fixed cur = (low + hi) * fixed::HALF;
        fixed_vector2 test_velocity = linear_velocity->get_internal() * cur;
        test_transform.set_origin(original_transform.get_origin() + test_velocity);
        internal->set_transform(test_transform);
        overlapping_bodies = world->get_overlapping_bodies(internal);
        if (overlapping_bodies->size() > 0) {
            hi = cur;

            // Update the last overlapping bodies.
            memdelete(last_overlapping_bodies);
            last_overlapping_bodies = overlapping_bodies;
        }
        else {
            low = cur;
            _set_fixed_position(get_fixed_position()->get_internal() + test_velocity);
            memdelete(overlapping_bodies);
        }
    }

    // @todo Find the shapes that collided so we can get the collision normal.
    memdelete(last_overlapping_bodies);

    return true;
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
