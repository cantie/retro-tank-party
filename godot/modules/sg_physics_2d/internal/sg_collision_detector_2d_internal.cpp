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

bool SGCollisionDetector2DInternal::AABB_overlaps_AABB(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2) {
    fixed_vector2 min_one = aabb1.get_min();
    fixed_vector2 max_one = aabb1.get_max();
    fixed_vector2 min_two = aabb2.get_min();
    fixed_vector2 max_two = aabb2.get_max();

    return (min_two.x <= max_one.x) && (min_one.x <= max_two.x) && \
           (min_two.y <= max_one.y) && (min_one.y <= max_two.y);
}

Interval SGCollisionDetector2DInternal::get_interval(const SGShape2DInternal &shape, const fixed_vector2 &axis) {
    Interval result;

    if (shape.get_shape_type() == SGShape2DInternal::ShapeType::SHAPE_CIRCLE) {
        const SGCircle2DInternal &circle = (const SGCircle2DInternal&)shape;
        fixed_transform2d t = shape.get_global_transform();
        fixed center = axis.dot(t.get_origin());
        fixed radius = circle.get_radius() * t.get_scale().x;
        result.min = center - radius;
        result.max = center + radius;
    }
    else {
        Vector<fixed_vector2> verts = shape.get_global_vertices();
        result.min = result.max = axis.dot(verts[0]);
        for (int i = 1; i < verts.size(); i++) {
            fixed projection = axis.dot(verts[i]);
            if (projection < result.min) {
                result.min = projection;
            }
            if (projection > result.max) {
                result.max = projection;
            }
        }
    }

    return result;
}

bool SGCollisionDetector2DInternal::overlaps_on_axis(const SGShape2DInternal &shape1, const SGShape2DInternal &shape2, const fixed_vector2 &axis, fixed &separation) {
    Interval i1 = get_interval(shape1, axis);
    Interval i2 = get_interval(shape2, axis);

    fixed d1 = i1.max - i2.min;
    fixed d2 = i2.max - i1.min;
    if (d1 >= fixed::ZERO && d2 >= fixed::ZERO) {
        separation = (d1 < d2) ? d1 : d2;
        // Add half to the seperation so we'd move to a non-overlapping state.
        separation += fixed::HALF;
        // Attempt to make the seperation relative to rectangle1.
        if (i1.min < i2.min) {
            separation = -separation;
        }
        return true;
    }

    return false;
}

bool SGCollisionDetector2DInternal::sat_test(const SGShape2DInternal &shape1, const SGShape2DInternal &shape2, const Vector<fixed_vector2> &axes, fixed_vector2 &best_separation_vector) {
    fixed separation_component;

    for (int i = 0; i < axes.size(); i++) {
        if (overlaps_on_axis(shape1, shape2, axes[i], separation_component)) {
            fixed_vector2 separation_vector = (axes[i] * separation_component);
            if (best_separation_vector == fixed_vector2::ZERO || separation_vector.length() < best_separation_vector.length()) {
                best_separation_vector = separation_vector;
            }
        }
        else {
            // Axis of separation found! They don't overlap.
            return false;
        }
    }

    // No axis of separation found, they overlap!
    return true;
}

bool SGCollisionDetector2DInternal::Rectangle_overlaps_Rectangle(const SGRectangle2DInternal &rectangle1, const SGRectangle2DInternal &rectangle2, OverlapInfo *p_info) {
    fixed_vector2 best_separation_vector;

    if (!sat_test(rectangle1, rectangle2, rectangle1.get_global_axes(), best_separation_vector)) {
        return false;
    }

    if (!sat_test(rectangle1, rectangle2, rectangle2.get_global_axes(), best_separation_vector)) {
        return false;
    }

    if (p_info) {
        p_info->separation = best_separation_vector;
    }

    return true;
}

bool SGCollisionDetector2DInternal::Circle_overlaps_Circle(const SGCircle2DInternal &circle1, const SGCircle2DInternal &circle2, OverlapInfo *p_info) {
    fixed_transform2d t1 = circle1.get_global_transform();
    fixed_transform2d t2 = circle2.get_global_transform();

    fixed_vector2 line = t1.get_origin() - t2.get_origin();

    // We only multiply by the scale.x because we don't support non-uniform scaling.
    fixed combined_radius = circle1.get_radius() * t1.get_scale().x + circle2.get_radius() * t2.get_scale().x;
    bool overlapping = (line.length_squared() <= combined_radius);

    if (overlapping && p_info) {
        // Add half to the seperation so we'd move to a non-overlapping state.
        p_info->separation = line.normalized() * (line.length() - (circle1.get_radius() + circle2.get_radius()) + fixed::HALF);
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

    bool overlapping = (line.length_squared() <= (radius * radius));
    if (overlapping && p_info) {
        // Add half to the seperation so we'd move to a non-overlapping state.
        p_info->separation = line.normalized() * (radius - line.length() + fixed::HALF);
    }

    return overlapping;
}

bool SGCollisionDetector2DInternal::Circle_overlaps_Rectangle(const SGCircle2DInternal &circle, const SGRectangle2DInternal &rectangle, OverlapInfo *p_info) {
    // Convert first rectangle into its own local space.
    fixed_rect2 aabb(-rectangle.get_extents(), rectangle.get_extents() * fixed::TWO);

    // Transform the circle into the local space of the rectangle.
    fixed_transform2d t = rectangle.get_global_transform();
    SGCircle2DInternal localized_circle(circle.get_radius());
    localized_circle.set_transform(t.affine_inverse() * circle.get_global_transform());

    bool overlapping = Circle_overlaps_AABB(localized_circle, aabb, p_info);

    if (overlapping && p_info) {
        // Transform the separation vector back into global space (but don't translate
        // because this is relative vector).
        p_info->separation = t.xform(p_info->separation) - t.elements[2];
    }

    return overlapping;
}

bool SGCollisionDetector2DInternal::Polygon_overlaps_Polygon(const SGPolygon2DInternal &polygon1, const SGPolygon2DInternal &polygon2, OverlapInfo *p_info) {
    if (polygon1.get_points().size() < 3) {
        return false;
    }
    if (polygon2.get_points().size() < 3) {
        return false;
    }

    fixed_vector2 best_separation_vector;

    if (!sat_test(polygon1, polygon2, polygon1.get_global_axes(), best_separation_vector)) {
        return false;
    }

    if (!sat_test(polygon1, polygon2, polygon2.get_global_axes(), best_separation_vector)) {
        return false;
    }

    if (p_info) {
        p_info->separation = best_separation_vector;
    }

    return true;
}

bool SGCollisionDetector2DInternal::Polygon_overlaps_Circle(const SGPolygon2DInternal &polygon, const SGCircle2DInternal &circle, OverlapInfo *p_info) {
    if (polygon.get_points().size() < 3) {
        return false;
    }

    fixed_vector2 best_separation_vector;

    // First, we see if the circle has any seperation from the polygon's axes.
    if (!sat_test(polygon, circle, polygon.get_global_axes(), best_separation_vector)) {
        return false;
    }

    // Next, we need to find the axis to check for the circle (it's a vector
    // from the closest vertex to the circle center).

    Vector<fixed_vector2> vertices = polygon.get_global_vertices();
    fixed_transform2d ct = circle.get_global_transform();
    fixed_vector2 closest_vertex = vertices[0];
    fixed closest_distance = (ct.get_origin() - vertices[0]).length_squared();

    for (int i = 1; i < vertices.size(); i++) {
        fixed distance = (ct.get_origin() - vertices[i]).length_squared();
        if (distance < closest_distance) {
            closest_distance = distance;
            closest_vertex = vertices[i];
        }
    }

    Vector<fixed_vector2> circle_axes;
    circle_axes.push_back((ct.get_origin() - closest_vertex).normalized());
    if (!sat_test(polygon, circle, circle_axes, best_separation_vector)) {
        return false;
    }

    if (p_info) {
        p_info->separation = best_separation_vector;
    }

    return true;
}

bool SGCollisionDetector2DInternal::Polygon_overlaps_Rectangle(const SGPolygon2DInternal &polygon, const SGRectangle2DInternal &rectangle, OverlapInfo *p_info) {
    if (polygon.get_points().size() < 3) {
        return false;
    }
    
    fixed_vector2 best_separation_vector;

    if (!sat_test(polygon, rectangle, polygon.get_global_axes(), best_separation_vector)) {
        return false;
    }

    if (!sat_test(polygon, rectangle, rectangle.get_global_axes(), best_separation_vector)) {
        return false;
    }

    if (p_info) {
        p_info->separation = best_separation_vector;
    }

    return true;
}

// Algorithm from https://stackoverflow.com/a/565282
//
// License: CC BY-SA 3.0
// Author: Gareth Rees
//
// p = p_start_1
// r = p_cast_to_1
// q = p_start_2
// s = p_cast_to_2
bool SGCollisionDetector2DInternal::segment_intersects_segment(const fixed_vector2 &p_start_1, const fixed_vector2 &p_cast_to_1, const fixed_vector2 &p_start_2, const fixed_vector2 &p_cast_to_2, fixed_vector2 &p_intersection_point) {
    fixed denominator = p_cast_to_1.cross(p_cast_to_2);
    fixed u_nominator = (p_start_2 - p_start_1).cross(p_cast_to_1);

    if (denominator == fixed::ZERO && u_nominator == fixed::ZERO) {
        // Line segments are collinear.
        //
        // They could overlap, but since we are always dealing with polygons,
        // we know that there will always be another edge that shares one of
        // the 2nd line segments end points, so we can trust that we'll
        // collide with that edge (so long as there aren't two collinear edges).
        return false;
    }

    if (denominator == fixed::ZERO) {
        // Line segments are parallel and so non-intersecting.
        return false;
    }

    fixed u = u_nominator / denominator;
    if (u < fixed::ZERO || u > fixed::ONE) {
        // Intersection would happen before the start or after the end of the 2nd segment.
        return false;
    }

    fixed t = (p_start_2 - p_start_1).cross(p_cast_to_2) / denominator;
    if (t < fixed::ZERO || t > fixed::ONE) {
        // Intersection would happen before the start or after the end of the 1st segment.
        return false;
    }

    p_intersection_point = p_start_1 + (p_cast_to_1 * t);

    return true;
}

bool SGCollisionDetector2DInternal::segment_intersects_Polygon(const fixed_vector2 &p_start, const fixed_vector2 &p_cast_to, const SGShape2DInternal &polygon, fixed_vector2 &p_intersection_point, fixed_vector2 &p_collision_normal) {
    Vector<fixed_vector2> verts = polygon.get_global_vertices();

    fixed_vector2 previous = verts[verts.size() - 1];
    for (int i = 0; i < verts.size(); i++) {
        fixed_vector2 cur = verts[i];
        fixed_vector2 edge = cur - previous;
        if (segment_intersects_segment(p_start, p_cast_to, previous, edge, p_intersection_point)) {
            p_collision_normal = fixed_vector2(edge.y, -edge.x).normalized();
            return true;
        }
        previous = cur;
    }

    return false;
}

// Algorithm from https://stackoverflow.com/a/1084899
//
// License: CC BY-SA 4.0
// Original author: bobobobo
//
// The code has been adapted to this engine and fixed-point path.
//
// E = p_start
// d = p_cast_to
bool SGCollisionDetector2DInternal::segment_intersects_Circle(const fixed_vector2 &p_start, const fixed_vector2 &p_cast_to, const SGCircle2DInternal &circle, fixed_vector2 &p_intersection_point, fixed_vector2 &p_collision_normal) {
    fixed_transform2d ct = circle.get_global_transform();

    fixed_vector2 C = ct.get_origin();
    fixed_vector2 f = p_start - C;

    fixed r = circle.get_radius() * ct.get_scale().x;

    fixed a = p_cast_to.dot(p_cast_to);
    if (a == fixed::ZERO) {
        // This would lead to division by zero.
        return false;
    }

    fixed b = fixed::TWO * f.dot(p_cast_to);
    fixed c = f.dot(f) - (r * r);

    // Reduce precision - we're just going to use whole integers to calculate
    // the determinant, in an attempt to avoid overflowing 64-bits.
    int64_t small_a = a.value >> 16;
    int64_t small_b = b.value >> 16;
    int64_t small_c = c.value >> 16;

    int64_t small_discriminant = (small_b * small_b) - (4 * small_a * small_c);
    if (small_discriminant < 0) {
        // No intersection.
        return false;
    }
    else {
        // Get the square root and return to our normal precision.
        fixed discriminant(sg_sqrt_64(small_discriminant) << 16);

        fixed t1 = (-b - discriminant) / (fixed::TWO * a);
        fixed t2 = (-b + discriminant) / (fixed::TWO * a);

        // This is where we're outside the circle, and intersect at least once.
        if (t1 >= fixed::ZERO && t1 <= fixed::ONE) {
            p_intersection_point = p_start + p_cast_to * t1;
            p_collision_normal = (p_intersection_point - C).normalized();
            return true;
        }

        // This is where we're inside the circle, and intersect the outer edge.
        if (t2 >= fixed::ZERO && t2 <= fixed::ONE) {
            p_intersection_point = p_start + p_cast_to * t2;
            p_collision_normal = (p_intersection_point - C).normalized();
            return true;
        }
    }

    return false;
}
