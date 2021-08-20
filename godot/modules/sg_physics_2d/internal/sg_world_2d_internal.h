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

#ifndef SG_WORLD_2D_INTERNAL_H
#define SG_WORLD_2D_INTERNAL_H

#include <core/object.h>

class SGArea2DInternal;
class SGBody2DInternal;
class SGCollisionObject2DInternal;
class SGShape2DInternal;

class SGWorld2DInternal {
    List<SGArea2DInternal *> areas;
    List<SGBody2DInternal *> bodies;
    List<SGShape2DInternal *> shapes;

    static SGWorld2DInternal *singleton;

public:
    static SGWorld2DInternal *get_singleton();

    void add_area(SGArea2DInternal *p_area);
    void remove_area(SGArea2DInternal *p_area);
    void add_body(SGBody2DInternal *p_body);
    void remove_body(SGBody2DInternal *p_body);
    void add_shape(SGShape2DInternal *p_shape);
    void remove_shape(SGShape2DInternal *p_shape);

    bool overlaps(SGCollisionObject2DInternal *p_object1, SGCollisionObject2DInternal *p_object2) const;
    bool overlaps(SGShape2DInternal *p_shape1, SGShape2DInternal *p_shape2) const;

    List<SGArea2DInternal *> *get_overlapping_areas(SGCollisionObject2DInternal *p_object) const;
    List<SGBody2DInternal *> *get_overlapping_bodies(SGCollisionObject2DInternal *p_object) const;

    SGWorld2DInternal();
    ~SGWorld2DInternal();
};

#endif
