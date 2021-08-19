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
public:

    enum ShapeType {
        SHAPE_RECTANGLE,
        SHAPE_CIRCLE,
    };

protected:
    friend class SGArea2DInternal;

    ShapeType shape_type;
    fixed_transform2d transform;
    SGArea2DInternal *owner;

    _FORCE_INLINE_ void set_owner(SGArea2DInternal *p_owner) { owner = p_owner; }

public:
    _FORCE_INLINE_ ShapeType get_shape_type() const { return shape_type; }

    _FORCE_INLINE_ fixed_transform2d get_transform() const { return transform; }
    _FORCE_INLINE_ void set_transform(const fixed_transform2d &p_transform) { transform = p_transform; }

    _FORCE_INLINE_ SGArea2DInternal *get_owner() const { return owner; }

    SGShape2DInternal(ShapeType p_shape_type) {
        shape_type = p_shape_type;
    }
    virtual ~SGShape2DInternal() {}
};

class SGRectangle2DInternal : public SGShape2DInternal {
protected:

    fixed_vector2 extents;

public:
    _FORCE_INLINE_ fixed_vector2 get_extents() const { return extents; }
    _FORCE_INLINE_ void set_extents(const fixed_vector2 &p_extents) { extents = p_extents; }

    fixed_rect2 get_bounds() const;

    SGRectangle2DInternal(fixed_vector2 p_extents) 
        : SGShape2DInternal(SHAPE_RECTANGLE) 
    {
        extents = p_extents;
    }
    SGRectangle2DInternal(fixed p_extents_w, fixed p_extents_h) 
        : SGRectangle2DInternal(fixed_vector2(p_extents_w, p_extents_h)) { }
};

class SGCircle2DInternal : public SGShape2DInternal {
protected:

    fixed radius;

public:
    _FORCE_INLINE_ fixed get_radius() const { return radius; }
    _FORCE_INLINE_ void set_radius(const fixed &p_radius) { radius = p_radius; }

    SGCircle2DInternal(fixed p_radius)
        : SGShape2DInternal(SHAPE_CIRCLE)
    {
        radius = p_radius;
    }
};

#endif
