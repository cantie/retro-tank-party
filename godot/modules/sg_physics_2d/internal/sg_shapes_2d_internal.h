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

#ifndef SG_SHAPES_2D_INTERNAL_H
#define SG_SHAPES_2D_INTERNAL_H

#include <core/resource.h>

#include "sg_fixed_math_internal.h"

class SGArea2DInternal;

class SGShape2DInternal {
protected:
    friend class SGArea2DInternal;

    fixed_vector2 position;
    SGArea2DInternal *owner;

    _FORCE_INLINE_ void set_owner(SGArea2DInternal *p_owner) { owner = p_owner; }

public:
    _FORCE_INLINE_ SGArea2DInternal *get_owner() const { return owner; }

    _FORCE_INLINE_ fixed_vector2 get_position() const { return position; }
    _FORCE_INLINE_ void set_position(const fixed_vector2 &p_position) { position = p_position; }

    virtual fixed_rect2 get_bounds() const = 0;

    virtual bool overlaps_shape(SGShape2DInternal *p_shape) = 0;

    SGShape2DInternal() {}
    virtual ~SGShape2DInternal() {}
};

class SGRectangle2DInternal : public SGShape2DInternal {
protected:

    fixed_vector2 extents;

public:

    _FORCE_INLINE_ fixed_vector2 get_extents() const { return extents; }
    _FORCE_INLINE_ void set_extents(const fixed_vector2 &p_extents) { extents = p_extents; }

    virtual fixed_rect2 get_bounds() const;
    virtual bool overlaps_shape(SGShape2DInternal *p_shape);

    SGRectangle2DInternal(fixed p_extents_w, fixed p_extents_h) {
        set_extents(fixed_vector2(p_extents_w, p_extents_h));
    }

};

#endif
