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

#include "sg_bodies_2d_internal.h"

#include "sg_world_2d_internal.h"

void SGCollisionObject2DInternal::add_shape(SGShape2DInternal *p_shape) {
    p_shape->set_owner(this);
    shapes.push_back(p_shape);
    SGWorld2DInternal::get_singleton()->add_shape(p_shape);
}

void SGCollisionObject2DInternal::remove_shape(SGShape2DInternal *p_shape) {
    p_shape->set_owner(nullptr);
    shapes.erase(p_shape);
    SGWorld2DInternal::get_singleton()->remove_shape(p_shape);
}

SGCollisionObject2DInternal::SGCollisionObject2DInternal() {
    data = nullptr;
}

SGCollisionObject2DInternal::~SGCollisionObject2DInternal() {
}

SGArea2DInternal::SGArea2DInternal() {
    SGWorld2DInternal::get_singleton()->add_area(this);
}

SGArea2DInternal::~SGArea2DInternal() {
    SGWorld2DInternal::get_singleton()->remove_area(this);
}

SGBody2DInternal::SGBody2DInternal(BodyType p_type) {
    type = p_type;
    SGWorld2DInternal::get_singleton()->add_body(this);
}

SGBody2DInternal::~SGBody2DInternal() {
    SGWorld2DInternal::get_singleton()->remove_body(this);
}
