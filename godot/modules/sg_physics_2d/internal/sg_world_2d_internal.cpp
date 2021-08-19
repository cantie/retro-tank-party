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

#include "sg_world_2d_internal.h"

#include "sg_bodies_2d_internal.h"
#include "sg_shapes_2d_internal.h"
#include "sg_collision_detector_2d_internal.h"

SGWorld2DInternal *SGWorld2DInternal::singleton = NULL;

SGWorld2DInternal *SGWorld2DInternal::get_singleton() {
    return singleton;
}

void SGWorld2DInternal::add_area(SGArea2DInternal *p_area) {
    areas.push_back(p_area);
}

void SGWorld2DInternal::remove_area(SGArea2DInternal *p_area) {
    areas.erase(p_area);
}

void SGWorld2DInternal::add_body(SGBody2DInternal *p_body) {
    bodies.push_back(p_body);
}

void SGWorld2DInternal::remove_body(SGBody2DInternal *p_body) {
    bodies.erase(p_body);
}

void SGWorld2DInternal::add_shape(SGShape2DInternal *p_shape) {
    shapes.push_back(p_shape);
}

void SGWorld2DInternal::remove_shape(SGShape2DInternal *p_shape) {
    shapes.erase(p_shape);
}

bool SGWorld2DInternal::overlaps(SGCollisionObject2DInternal *p_object1, SGCollisionObject2DInternal *p_object2) const {
    for (const List<SGShape2DInternal *>::Element *S1 = p_object1->get_shapes().front(); S1; S1 = S1->next()) {
        for (const List<SGShape2DInternal *>::Element *S2 = p_object2->get_shapes().front(); S2; S2 = S2->next()) {
            if (overlaps(S1->get(), S2->get())) {
                return true;
            }
        }
    }

    return false;
}

bool SGWorld2DInternal::overlaps(SGShape2DInternal *p_shape1, SGShape2DInternal *p_shape2) const {
    using ShapeType = SGShape2DInternal::ShapeType;

    ShapeType shape1_type = p_shape1->get_shape_type();
    ShapeType shape2_type = p_shape2->get_shape_type();

    if (shape1_type == ShapeType::SHAPE_RECTANGLE && shape2_type == ShapeType::SHAPE_RECTANGLE) {
        return SGCollisionDetector2DInternal::Rectangle_overlaps_Rectangle(*((SGRectangle2DInternal *)p_shape1), *((SGRectangle2DInternal *)p_shape2));
    }
    else if (shape1_type == ShapeType::SHAPE_CIRCLE && shape2_type == ShapeType::SHAPE_CIRCLE) {
        return SGCollisionDetector2DInternal::Circle_overlaps_Circle(*((SGCircle2DInternal *)p_shape1), *((SGCircle2DInternal *)p_shape2));
    }
    else if (shape1_type == ShapeType::SHAPE_CIRCLE && shape2_type == ShapeType::SHAPE_RECTANGLE) {
        return SGCollisionDetector2DInternal::Circle_overlaps_Rectangle(*((SGCircle2DInternal *)p_shape1), *((SGRectangle2DInternal *)p_shape2));
    }
    else if (shape1_type == ShapeType::SHAPE_RECTANGLE && shape2_type == ShapeType::SHAPE_CIRCLE) {
        return SGCollisionDetector2DInternal::Circle_overlaps_Rectangle(*((SGCircle2DInternal *)p_shape2), *((SGRectangle2DInternal *)p_shape1));
    }

    return false;
}

List<SGArea2DInternal *> *SGWorld2DInternal::get_overlapping_areas(SGArea2DInternal *p_area) const {
    List<SGArea2DInternal *> *ret = memnew(List<SGArea2DInternal *>);

    for (const List<SGArea2DInternal *>::Element *E = areas.front(); E; E = E->next()) {
        SGArea2DInternal *other_area = E->get();
        if (other_area == p_area) {
            continue;
        }

        if (overlaps(p_area, other_area)) {
            ret->push_back(other_area);
        }
    }

    return ret;
}

List<SGBody2DInternal *> *SGWorld2DInternal::get_overlapping_bodies(SGArea2DInternal *p_area) const {
    List<SGBody2DInternal *> *ret = memnew(List<SGBody2DInternal *>);

    for (const List<SGBody2DInternal *>::Element *E = bodies.front(); E; E = E->next()) {
        SGBody2DInternal *other_body = E->get();
        if (overlaps(p_area, other_body)) {
            ret->push_back(other_body);
        }
    }

    return ret;
}

SGWorld2DInternal::SGWorld2DInternal()
{
    singleton = this;
}

SGWorld2DInternal::~SGWorld2DInternal() {
    singleton = nullptr;
}
