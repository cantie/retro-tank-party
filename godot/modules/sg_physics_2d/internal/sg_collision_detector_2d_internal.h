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

#ifndef SG_COLLISION_DETECTOR_2D_INTERNAL_H
#define SG_COLLISION_DETECTOR_2D_INTERNAL_H

#include "sg_fixed_math_internal.h"
#include "sg_shapes_2d_internal.h"

class SGCollisionDetector2DInternal {
public:

    //
    // Rectangles
    //

    struct Interval {
        fixed min;
        fixed max;
    };

    struct OverlapInfo {
        fixed_vector2 seperation;
    };

    static Interval get_interval(const fixed_rect2 &aabb, const fixed_vector2 &axis);
    static Interval get_interval(const SGRectangle2DInternal &rectangle, const fixed_vector2 &axis);

    static bool overlaps_on_axis(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2, const fixed_vector2 &axis);
    static bool overlaps_on_axis(const fixed_rect2 &aabb, const SGRectangle2DInternal &rectangle, const fixed_vector2 &axis);

    static bool AABB_overlaps_AABB(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2, OverlapInfo *p_info = nullptr);
    static bool AABB_overlaps_AABB_SAT(const fixed_rect2 &aabb1, const fixed_rect2 &aabb2, OverlapInfo *p_info = nullptr);
    static bool AABB_overlaps_Rectangle(const fixed_rect2 &aabb, const SGRectangle2DInternal &rectangle, OverlapInfo *p_info = nullptr);
    static bool Rectangle_overlaps_Rectangle(const SGRectangle2DInternal &rectangle1, const SGRectangle2DInternal &rectangle2, OverlapInfo *p_info = nullptr);

    //
    // Circles
    //

    static bool Circle_overlaps_Circle(const SGCircle2DInternal &circle1, const SGCircle2DInternal &circle2, OverlapInfo *p_info = nullptr);
    static bool Circle_overlaps_AABB(const SGCircle2DInternal &circle, const fixed_rect2 &aabb, OverlapInfo *p_info = nullptr);
    static bool Circle_overlaps_Rectangle(const SGCircle2DInternal &circle, const SGRectangle2DInternal &rectangle, OverlapInfo *p_info = nullptr);

};

#endif

