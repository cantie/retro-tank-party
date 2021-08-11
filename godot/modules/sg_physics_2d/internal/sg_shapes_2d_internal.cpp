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

fixed_rect2 SGRectangle2DInternal::get_bounds() const {
    return fixed_rect2(position, extents);
}

bool SGRectangle2DInternal::overlaps_shape(SGShape2DInternal *p_shape) {
    return false;
}

/*
bool SGPhysics2DServer::shape_overlaps(RID p_shape_one, RID p_shape_two) {

    SGRectangle2DInternal *rect1 = static_cast<SGRectangle2DInternal *>(p_shape_one.get_data());
    SGRectangle2DInternal *rect2 = static_cast<SGRectangle2DInternal *>(p_shape_two.get_data());

    fixed_vector2 min_one = rect1->get_bounds().get_min();
    fixed_vector2 max_one = rect1->get_bounds().get_max();
    fixed_vector2 min_two = rect2->get_bounds().get_min();
    fixed_vector2 max_two = rect2->get_bounds().get_max();

    return (min_two.x <= max_one.x) && (min_one.x <= max_two.x) && \
           (min_two.y <= max_one.y) && (min_one.y <= max_two.y);
}
*/
