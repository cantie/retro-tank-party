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

bool SGWorld2DInternal::overlaps(SGCollisionObject2DInternal *p_object1, SGCollisionObject2DInternal *p_object2, SGWorld2DInternal::OverlapInfo *p_info) const {
    for (const List<SGShape2DInternal *>::Element *S1 = p_object1->get_shapes().front(); S1; S1 = S1->next()) {
        for (const List<SGShape2DInternal *>::Element *S2 = p_object2->get_shapes().front(); S2; S2 = S2->next()) {
            if (overlaps(S1->get(), S2->get(), p_info)) {
                return true;
            }
        }
    }

    return false;
}

bool SGWorld2DInternal::overlaps(SGShape2DInternal *p_shape1, SGShape2DInternal *p_shape2, SGWorld2DInternal::OverlapInfo *p_info) const {
    using ShapeType = SGShape2DInternal::ShapeType;

    ShapeType shape1_type = p_shape1->get_shape_type();
    ShapeType shape2_type = p_shape2->get_shape_type();

    SGCollisionDetector2DInternal::OverlapInfo overlap_info;
    SGCollisionDetector2DInternal::OverlapInfo *overlap_info_ptr = p_info ? &overlap_info : nullptr;

    bool overlapping = false;
    bool swap = false;

    if (shape1_type == ShapeType::SHAPE_RECTANGLE && shape2_type == ShapeType::SHAPE_RECTANGLE) {
        overlapping = SGCollisionDetector2DInternal::Rectangle_overlaps_Rectangle(*((SGRectangle2DInternal *)p_shape1), *((SGRectangle2DInternal *)p_shape2), overlap_info_ptr);
    }
    else if (shape1_type == ShapeType::SHAPE_CIRCLE && shape2_type == ShapeType::SHAPE_CIRCLE) {
        overlapping = SGCollisionDetector2DInternal::Circle_overlaps_Circle(*((SGCircle2DInternal *)p_shape1), *((SGCircle2DInternal *)p_shape2), overlap_info_ptr);
    }
    else if (shape1_type == ShapeType::SHAPE_CIRCLE && shape2_type == ShapeType::SHAPE_RECTANGLE) {
        overlapping = SGCollisionDetector2DInternal::Circle_overlaps_Rectangle(*((SGCircle2DInternal *)p_shape1), *((SGRectangle2DInternal *)p_shape2), overlap_info_ptr);
    }
    else if (shape1_type == ShapeType::SHAPE_RECTANGLE && shape2_type == ShapeType::SHAPE_CIRCLE) {
        overlapping = SGCollisionDetector2DInternal::Circle_overlaps_Rectangle(*((SGCircle2DInternal *)p_shape2), *((SGRectangle2DInternal *)p_shape1), overlap_info_ptr);
        swap = true;
    }
    else if (shape1_type == ShapeType::SHAPE_POLYGON && shape2_type == ShapeType::SHAPE_POLYGON) {
        overlapping = SGCollisionDetector2DInternal::Polygon_overlaps_Polygon(*((SGPolygon2DInternal *)p_shape1), *((SGPolygon2DInternal *)p_shape2), overlap_info_ptr);
    }
    else if (shape1_type == ShapeType::SHAPE_POLYGON && shape2_type == ShapeType::SHAPE_CIRCLE) {
        overlapping = SGCollisionDetector2DInternal::Polygon_overlaps_Circle(*((SGPolygon2DInternal *)p_shape1), *((SGCircle2DInternal *)p_shape2), overlap_info_ptr);
    }
    else if (shape1_type == ShapeType::SHAPE_CIRCLE && shape2_type == ShapeType::SHAPE_POLYGON) {
        overlapping = SGCollisionDetector2DInternal::Polygon_overlaps_Circle(*((SGPolygon2DInternal *)p_shape2), *((SGCircle2DInternal *)p_shape1), overlap_info_ptr);
        swap = true;
    }
    else if (shape1_type == ShapeType::SHAPE_POLYGON && shape2_type == ShapeType::SHAPE_RECTANGLE) {
        overlapping = SGCollisionDetector2DInternal::Polygon_overlaps_Rectangle(*((SGPolygon2DInternal *)p_shape1), *((SGRectangle2DInternal *)p_shape2), overlap_info_ptr);
    }
    else if (shape1_type == ShapeType::SHAPE_RECTANGLE && shape2_type == ShapeType::SHAPE_POLYGON) {
        overlapping = SGCollisionDetector2DInternal::Polygon_overlaps_Rectangle(*((SGPolygon2DInternal *)p_shape2), *((SGRectangle2DInternal *)p_shape1), overlap_info_ptr);
        swap = true;
    }

    if (overlapping && p_info) {
        // Make sure the info is from the perspective of the first shape.
        p_info->shape = p_shape2;
        p_info->seperation = swap ? -overlap_info.separation : overlap_info.separation;
    }

    return overlapping;
}

bool SGWorld2DInternal::get_best_overlapping_body(SGCollisionObject2DInternal *p_object, SGWorld2DInternal::OverlapInfo *p_info) const {
    for (const List<SGBody2DInternal *>::Element *E = bodies.front(); E; E = E->next()) {
        SGBody2DInternal *other = E->get();
        if (other == p_object) {
            continue;
        }

        if (!p_object->test_collision_layers(other)) {
            continue;
        }

        if (overlaps(p_object, other, p_info)) {
            // @todo We should return the info for the collision with the deepest penetration.
            // For now, just return the info for the first overlapping shape.
            p_info->body = other;
            return true;
        }
    }

    return false;
}

List<SGArea2DInternal *> *SGWorld2DInternal::get_overlapping_areas(SGCollisionObject2DInternal *p_object) const {
    List<SGArea2DInternal *> *ret = memnew(List<SGArea2DInternal *>);

    for (const List<SGArea2DInternal *>::Element *E = areas.front(); E; E = E->next()) {
        SGArea2DInternal *other = E->get();
        if (other == p_object) {
            continue;
        }

        if (!p_object->test_collision_layers(other)) {
            continue;
        }

        if (overlaps(p_object, other)) {
            ret->push_back(other);
        }
    }

    return ret;
}

List<SGBody2DInternal *> *SGWorld2DInternal::get_overlapping_bodies(SGCollisionObject2DInternal *p_object) const {
    List<SGBody2DInternal *> *ret = memnew(List<SGBody2DInternal *>);

    for (const List<SGBody2DInternal *>::Element *E = bodies.front(); E; E = E->next()) {
        SGBody2DInternal *other = E->get();
        if (other == p_object) {
            continue;
        }

        if (!p_object->test_collision_layers(other)) {
            continue;
        }

        if (overlaps(p_object, other)) {
            ret->push_back(other);
        }
    }

    return ret;
}

bool SGWorld2DInternal::segment_intersects_shape(const fixed_vector2 &p_start, const fixed_vector2 &p_cast_to, SGShape2DInternal *p_shape, fixed_vector2 &p_intersection_point, fixed_vector2 &p_collision_normal) const {
    using ShapeType = SGShape2DInternal::ShapeType;

    ShapeType shape_type = p_shape->get_shape_type();

    switch (shape_type) {
        case ShapeType::SHAPE_RECTANGLE:
        case ShapeType::SHAPE_POLYGON:
            return SGCollisionDetector2DInternal::segment_intersects_Polygon(p_start, p_cast_to, *(SGShape2DInternal *)p_shape, p_intersection_point, p_collision_normal);
        
        case ShapeType::SHAPE_CIRCLE:
            return SGCollisionDetector2DInternal::segment_intersects_Circle(p_start, p_cast_to, *(SGCircle2DInternal *)p_shape, p_intersection_point, p_collision_normal);

    }

    return false;
}

bool SGWorld2DInternal::cast_ray(const fixed_vector2 &p_start, const fixed_vector2 &p_cast_to, uint32_t p_collision_mask, RayCastInfo *p_info) const {
    SGBody2DInternal *collider = nullptr;
    int64_t shortest_distance_squared;
    fixed_vector2 closest_intersection_point;
    fixed_vector2 closest_collision_normal;

    fixed_vector2 intersection_point;
    fixed_vector2 collision_normal;

    for (const List<SGBody2DInternal *>::Element *E = bodies.front(); E; E = E->next()) {
        SGBody2DInternal *other = E->get();
        if (!(other->get_collision_layer() & p_collision_mask)) {
            continue;
        }

        for (const List<SGShape2DInternal *>::Element *S = other->get_shapes().front(); S; S = S->next()) {
            SGShape2DInternal *shape = S->get();
            if (segment_intersects_shape(p_start, p_cast_to, shape, intersection_point, collision_normal)) {
                if (p_info == nullptr) {
                    return true;
                }

                int64_t distance_squared = (intersection_point - p_start).length_squared_64();
                if (collider == nullptr || distance_squared < shortest_distance_squared) {
                    shortest_distance_squared = distance_squared;
                    collider = other;
                    closest_intersection_point = intersection_point;
                    closest_collision_normal = collision_normal;
                }
            }
        }
    }

    if (p_info && collider) {
        p_info->body = collider;
        p_info->collision_point = closest_intersection_point;
        p_info->collision_normal = closest_collision_normal;
        return true;
    }

    return false;
}

SGWorld2DInternal::SGWorld2DInternal()
{
    singleton = this;
}

SGWorld2DInternal::~SGWorld2DInternal() {
    singleton = nullptr;
}
