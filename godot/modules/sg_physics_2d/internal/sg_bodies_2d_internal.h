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

#ifndef SG_BODIES_2D_INTERNAL_H
#define SG_BODIES_2D_INTERNAL_H

#include <core/vector.h>

#include "sg_shapes_2d_internal.h"

class SGBroadphase2DInternal;
class SGBroadphase2DInternalElement;

class SGCollisionObject2DInternal {
public:
    enum Type {
        TYPE_AREA = 1,
        TYPE_BODY = 2,
        TYPE_BOTH = (TYPE_AREA | TYPE_BODY),
    };

private:
    Type type;
    fixed_transform2d transform;
    List<SGShape2DInternal *> shapes;
    SGBroadphase2DInternal *broadphase;
    SGBroadphase2DInternalElement *broadphase_element;
    void *data;

    uint32_t collision_layer;
    uint32_t collision_mask;
    
public:
    _FORCE_INLINE_ Type get_type() const { return type; }

    _FORCE_INLINE_ fixed_transform2d get_transform() const { return transform; }
    void set_transform(const fixed_transform2d &p_transform);

    void add_shape(SGShape2DInternal *p_shape);
    void remove_shape(SGShape2DInternal *p_shape);

    _FORCE_INLINE_ const List<SGShape2DInternal *> &get_shapes() const {
        return shapes;
    }

    fixed_rect2 get_bounds() const;
   
    void add_to_broadphase(SGBroadphase2DInternal *p_broadphase);
    void remove_from_broadphase();

    _FORCE_INLINE_ void set_data(void *p_data) { data = p_data; }
    _FORCE_INLINE_ void *get_data() const { return data; }

    _FORCE_INLINE_ void set_collision_layer(uint32_t p_collision_layer) { collision_layer = p_collision_layer; }
    _FORCE_INLINE_ uint32_t get_collision_layer() const { return collision_layer; }

    _FORCE_INLINE_ void set_collision_mask(uint32_t p_collision_mask) { collision_mask = p_collision_mask; }
    _FORCE_INLINE_ uint32_t get_collision_mask() const { return collision_mask; }

    _FORCE_INLINE_ bool test_collision_layers(SGCollisionObject2DInternal *p_other) const {
        return (collision_layer & p_other->collision_mask) || (p_other->collision_layer & collision_mask);
    }

    SGCollisionObject2DInternal(Type p_type);
    virtual ~SGCollisionObject2DInternal();

};

class SGArea2DInternal : public SGCollisionObject2DInternal {
public:
    SGArea2DInternal();
    ~SGArea2DInternal();
};

class SGBody2DInternal : public SGCollisionObject2DInternal {
public:

    enum BodyType {
        BODY_STATIC,
        BODY_KINEMATIC,
    };

protected:
    BodyType type;

public:
    _FORCE_INLINE_ BodyType get_type() const { return type; }

    SGBody2DInternal(BodyType p_type);
    ~SGBody2DInternal();
};

#endif
