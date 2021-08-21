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

#include "sg_collision_detector_2d_internal.h"

using Interval = SGCollisionDetector2DInternal::Interval;

Interval SGCollisionDetector2DInternal::get_interval(const fixed_rect2 &aabb, const fixed_vector2 &axis) {
    Interval result;

    fixed_vector2 min = aabb.get_min();
    fixed_vector2 max = aabb.get_max();

    fixed_vector2 verts[] = {
        fixed_vector2(min.x, min.y), fixed_vector2(max.x, min.y),
        fixed_vector2(min.x, max.y), fixed_vector2(max.x, max.y),
    };

    result.min = result.max = axis.dot(verts[0]);
    for (int i = 1; i < 4; i++) {
        fixed projection = axis.dot(verts[i]);
        if (projection < result.min) {
            result.min = projection;
        }
        if (projection > result.max) {
            result.max = projection;
        }
    }

    return result;
}

Interval SGCollisionDetector2DInternal::get_interval(const SGRectangle2DInternal &rectangle, const fixed_vector2 &axis) {
    fixed_rect2 bounds = rectangle.get_bounds();

    fixed_vector2 min = bounds.get_min();
    fixed_vector2 max = bounds.get_max();

    // @todo This isn't quite right, because bounds will already include the scale, which will get double applied in a moment.
    fixed_vector2 verts[] = {
        fixed_vector2(min.x, min.y), fixed_vector2(max.x, min.y),
        fixed_vector2(min.x, max.y), fixed_vector2(max.x, max.y),
    };

    for (int i = 0; i < 4; i++) {
        verts[i] = rectangle.get_global_transform().xform(verts[i] - bounds.position);
    }

    // @todo We can reuse the above verts for all the axes.

    Interval result;
    result.min = result.max = axis.dot(verts[0]);
    for (int i = 1; i < 4; i++) {
        fixed projection = axis.dot(verts[i]);
        if (projection < result.min) {
            result.min = projection;
        }
        if (projection > result.max) {
            result.max = projection;
        }
    }

    return result;
}

bool SGCollisionDetector2DInternal::overlaps_on_axis(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2, const fixed_vector2 &axis) {
    Interval i1 = get_interval(aabb1, axis);
    Interval i2 = get_interval(aabb2, axis);
    return ((i2.min <= i1.max) && (i1.min <= i2.max));
}

bool SGCollisionDetector2DInternal::overlaps_on_axis(const fixed_rect2 &aabb, const SGRectangle2DInternal &rectangle, const fixed_vector2 &axis) {
    Interval i1 = get_interval(aabb, axis);
    Interval i2 = get_interval(rectangle, axis);
    return ((i2.min <= i1.max) && (i1.min <= i2.max));
}

bool SGCollisionDetector2DInternal::AABB_overlaps_AABB(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2, OverlapInfo *p_info) {
    fixed_vector2 min_one = aabb1.get_min();
    fixed_vector2 max_one = aabb1.get_max();
    fixed_vector2 min_two = aabb2.get_min();
    fixed_vector2 max_two = aabb2.get_max();

    return (min_two.x <= max_one.x) && (min_one.x <= max_two.x) && \
           (min_two.y <= max_one.y) && (min_one.y <= max_two.y);
}

bool SGCollisionDetector2DInternal::AABB_overlaps_AABB_SAT(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2, OverlapInfo *p_info) {
    fixed_vector2 axes[] = {
        fixed_vector2(fixed::ONE, fixed::ZERO),
        fixed_vector2(fixed::ZERO, fixed::ONE),
    };

    for (int i = 0; i < 2; i++) {
        if (!overlaps_on_axis(aabb1, aabb2, axes[i])) {
            // Axis of seperation found! They don't overlap.
            return false;
        }
    }

    // No axis of seperation found, they overlap.
    return true;
}

bool SGCollisionDetector2DInternal::AABB_overlaps_Rectangle(const fixed_rect2 &aabb, const SGRectangle2DInternal &rectangle, OverlapInfo *p_info) {
    fixed_vector2 axes[] = {
        fixed_vector2(fixed::ONE, fixed::ZERO),
        fixed_vector2(fixed::ZERO, fixed::ONE),
        rectangle.get_global_transform().xform(fixed_vector2(rectangle.get_extents().x, fixed::ZERO)).normalized(),
        rectangle.get_global_transform().xform(fixed_vector2(fixed::ZERO, rectangle.get_extents().y)).normalized(),
    };

    for (int i = 0; i < 4; i++) {
        if (!overlaps_on_axis(aabb, rectangle, axes[i])) {
            return false;
        }
    }

    return true;
}

bool SGCollisionDetector2DInternal::Rectangle_overlaps_Rectangle(const SGRectangle2DInternal &rectangle1, const SGRectangle2DInternal &rectangle2, OverlapInfo *p_info) {
    // Convert first rectangle into its own local space.
    fixed_rect2 aabb(fixed_vector2(), rectangle1.get_extents());

    // Transform the second rectangle into the local space of the first.
    SGRectangle2DInternal localized_rectangle2(rectangle2.get_extents());
    localized_rectangle2.set_transform(rectangle1.get_global_transform().affine_inverse() * rectangle2.get_global_transform());

    return AABB_overlaps_Rectangle(aabb, localized_rectangle2);
}

bool SGCollisionDetector2DInternal::Circle_overlaps_Circle(const SGCircle2DInternal &circle1, const SGCircle2DInternal &circle2, OverlapInfo *p_info) {
    fixed_transform2d t1 = circle1.get_global_transform();
    fixed_transform2d t2 = circle2.get_global_transform();

    fixed_vector2 line = t2.get_origin() - t1.get_origin();
    // We need to use 64-bit integer math so we don't overflow 32-bits with
    // all these big squared values.
    // We only multiply by the scale.x because we don't support non-uniform scaling.

    int64_t combined_radius = (int64_t)circle1.get_radius().value * (int64_t)t1.get_scale().x.value + (int64_t)circle2.get_radius().value * (int64_t)t2.get_scale().x.value;
    bool overlapping = (line.length_squared_64() <= combined_radius);

    if (overlapping && p_info) {
        p_info->seperation = line;
    }

    return overlapping;
}

bool SGCollisionDetector2DInternal::Circle_overlaps_AABB(const SGCircle2DInternal &circle, const fixed_rect2 &aabb, OverlapInfo *p_info) {
    fixed_vector2 min = aabb.get_min();
    fixed_vector2 max = aabb.get_max();

    fixed_transform2d t = circle.get_global_transform();

    fixed_vector2 closest_point = t.get_origin();
    closest_point.x = CLAMP(closest_point.x, min.x, max.x);
    closest_point.y = CLAMP(closest_point.y, min.y, max.y);

    fixed_vector2 line = t.get_origin() - closest_point;
    // We only multiply by the scale.x because we don't support non-uniform scaling.
    fixed radius = circle.get_radius() * t.get_scale().x;

    // We need to use 64-bit integer math so we don't overflow 32-bits with
    // all these big squared values.
    int64_t radius_squared_64 = (int64_t)radius.value * (int64_t)radius.value;
    bool overlapping = (line.length_squared_64() <= radius_squared_64);

    if (overlapping && p_info) {
        p_info->seperation = line;
    }

    return overlapping;
}

bool SGCollisionDetector2DInternal::Circle_overlaps_Rectangle(const SGCircle2DInternal &circle, const SGRectangle2DInternal &rectangle, OverlapInfo *p_info) {
    // Convert first rectangle into its own local space.
    fixed_rect2 aabb(fixed_vector2(), rectangle.get_extents());

    // Transform the circle into the local space of the rectangle.
    SGCircle2DInternal localized_circle(circle.get_radius());
    localized_circle.set_transform(rectangle.get_global_transform().affine_inverse() * circle.get_global_transform());

    bool overlapping = Circle_overlaps_AABB(localized_circle, aabb, p_info);

    if (overlapping && p_info) {
        // Transform the seperation vector back into global space.
        p_info->seperation = rectangle.get_global_transform().xform(p_info->seperation);
    }

    return overlapping;
}
