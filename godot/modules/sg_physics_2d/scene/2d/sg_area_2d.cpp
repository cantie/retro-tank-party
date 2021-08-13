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

#include "sg_area_2d.h"

#include <core/engine.h>

#include "../../internal/sg_world_2d_internal.h"
#include "../../internal/sg_bodies_2d_internal.h"
#include "../../internal/sg_shapes_2d_internal.h"

void SGArea2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_overlapping_areas"), &SGArea2D::get_overlapping_areas);
}

void SGArea2D::add_shape(SGShape2DInternal *p_shape) {
    area->add_shape(p_shape);
}

void SGArea2D::remove_shape(SGShape2DInternal *p_shape) {
    area->remove_shape(p_shape);
}

Array SGArea2D::get_overlapping_areas() const {
    Array ret;

    List<SGArea2DInternal *> *overlapping_areas = SGWorld2DInternal::get_singleton()->get_overlapping_areas(area);
    for (List<SGArea2DInternal *>::Element *E = overlapping_areas->front(); E; E = E->next()) {
        SGArea2D *overlapping_area = Object::cast_to<SGArea2D>((Object *)E->get()->get_data());
        if (overlapping_area) {
            ret.push_back(overlapping_area);
        }
    }
    memdelete(overlapping_areas);

    return ret;
}

SGArea2D::SGArea2D() {
    area = memnew(SGArea2DInternal);
    area->set_data(this);
}

SGArea2D::~SGArea2D() {
    memdelete(area);
}
