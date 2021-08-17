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

#ifndef SG_SHAPES_2D_H
#define SG_SHAPES_2D_H

#include <core/resource.h>

#include "../../math/sg_fixed_vector2.h"

class SGShape2DInternal;

class SGShape2D : public Resource {
	GDCLASS(SGShape2D, Resource);
	OBJ_SAVE_TYPE(SGShape2D);

    friend class SGCollisionShape2D;
    
    SGShape2DInternal *shape;

protected:
    static void _bind_methods();

    inline SGShape2DInternal *get_shape_internal() const { return shape; }

    SGShape2D(SGShape2DInternal *shape);
public:
    virtual void sync_to_physics_engine(const fixed_transform2d &p_global_position) const = 0;

    virtual void draw(const RID &p_to_rid, const Color &p_color) = 0;

    virtual ~SGShape2D();
};


class SGRectangleShape2D : public SGShape2D {
	GDCLASS(SGRectangleShape2D, SGShape2D);
	OBJ_SAVE_TYPE(SGRectangleShape2D);

    Ref<SGFixedVector2> extents;

protected:
    static void _bind_methods();

public:
    void set_extents(const Ref<SGFixedVector2>& p_extents);
	Ref<SGFixedVector2> get_extents();

    virtual void sync_to_physics_engine(const fixed_transform2d &p_global_position) const override;

    virtual void draw(const RID &p_to_rid, const Color &p_color) override;

    SGRectangleShape2D();
    ~SGRectangleShape2D();
};

#endif
