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

#include "sg_shapes_2d.h"

void SGShape2D::_bind_methods() {
    // @todo?
}

SGRectangleShape2D::SGRectangleShape2D() {
    extents = Ref<FixedVector2>(memnew(FixedVector2));
}

SGRectangleShape2D::~SGRectangleShape2D() {
}

void SGRectangleShape2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_extents"), &SGRectangleShape2D::get_extents);
    ClassDB::bind_method(D_METHOD("set_extents", "extents"), &SGRectangleShape2D::set_extents);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "extents", PROPERTY_HINT_TYPE_STRING, "FixedVector2"), "set_extents", "get_extents");
}

void SGRectangleShape2D::set_extents(const Ref<FixedVector2>& p_extents) {
    extents = p_extents;
}

Ref<FixedVector2> SGRectangleShape2D::get_extents() {
    return extents;
}
