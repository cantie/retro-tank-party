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

#include "sg_shapes_2d_internal.h"

#include "sg_bodies_2d_internal.h"

fixed_transform2d SGShape2DInternal::get_global_transform() const {
    if (!owner) {
        return transform;
    }
    if (global_xform_dirty) {
        global_transform = owner->get_transform() * transform;
        global_xform_dirty = false;
    }
    return global_transform;
}

Vector<fixed_vector2> SGShape2DInternal::get_global_vertices() const {
    return global_vertices;
}

Vector<fixed_vector2> SGShape2DInternal::get_global_axes() const {
    return global_axes;
}

fixed_rect2 SGShape2DInternal::get_bounds() const {
    Vector<fixed_vector2> points = get_global_vertices();
    if (points.size() == 0) {
        return fixed_rect2(global_transform.get_origin(), fixed_vector2());
    }

    fixed_rect2 bounds(points[0], fixed_vector2());
    for (int i = 1; i < points.size(); i++) {
        bounds.expand_to(points[i]);
    }

    return bounds;
}

Vector<fixed_vector2> SGRectangle2DInternal::get_global_vertices() const {
    if (global_vertices.size() == 0) {
        fixed_transform2d t = get_global_transform();

        global_vertices.resize(4);
        global_vertices.write[0] = t.xform(fixed_vector2(-extents.x, -extents.y));
        global_vertices.write[1] = t.xform(fixed_vector2(extents.x, -extents.y));
        global_vertices.write[2] = t.xform(fixed_vector2(extents.x, extents.y));
        global_vertices.write[3] = t.xform(fixed_vector2(-extents.x, extents.y));
    }

    return global_vertices;
}

Vector<fixed_vector2> SGRectangle2DInternal::get_global_axes() const {
    if (global_axes.size() == 0) {
        fixed_transform2d t = get_global_transform();
        t.set_origin(fixed_vector2::ZERO);

        global_axes.resize(2);
        global_axes.write[0] = t.xform(fixed_vector2(extents.x, fixed::ZERO)).normalized();
        global_axes.write[1] = t.xform(fixed_vector2(fixed::ZERO, extents.y)).normalized();
    }

    return global_axes;
}

Vector<fixed_vector2> SGPolygon2DInternal::get_global_vertices() const {
    if (global_vertices.size() == 0 && points.size() > 0) {
        fixed_transform2d t = get_global_transform();

        global_vertices.resize(points.size());
        for (int i = 0; i < points.size(); i++) {
            global_vertices.write[i] = t.xform(points[i]);
        }
    }

    return global_vertices;
}

Vector<fixed_vector2> SGPolygon2DInternal::get_global_axes() const {
    if (global_axes.size() == 0) {
        fixed_transform2d t = get_global_transform();
        t.set_origin(fixed_vector2::ZERO);

        global_axes.resize(points.size());
        for (int i = 0; i < points.size(); i++) {
            int next_index = (i == points.size() - 1) ? 0 : i + 1;
            fixed_vector2 edge = t.xform(points[next_index] - points[i]);
            // Get the vector perpendicular to the edge, which will be the edge normal.
            global_axes.write[i] = fixed_vector2(edge.y, -edge.x).normalized();
        }
    }

    return global_axes;
}

fixed_rect2 SGCircle2DInternal::get_bounds() const {
    fixed_transform2d t = get_global_transform();
    fixed diameter(radius.value << 1);
    return fixed_rect2(t.get_origin(), fixed_vector2(diameter, diameter) * t.get_scale().x);
}
