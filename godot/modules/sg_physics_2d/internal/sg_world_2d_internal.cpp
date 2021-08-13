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

#include "sg_world_2d_internal.h"

#include "sg_bodies_2d_internal.h"
#include "sg_shapes_2d_internal.h"

SGWorld2DInternal *SGWorld2DInternal::singleton = NULL;

SGWorld2DInternal *SGWorld2DInternal::get_singleton() {
    return singleton;
}

void SGWorld2DInternal::add_area(SGArea2DInternal *p_area) {
    areas.push_back(p_area);
}

void SGWorld2DInternal::remove_area(SGArea2DInternal *p_area) {
    areas.erase(p_area);
}

void SGWorld2DInternal::add_shape(SGShape2DInternal *p_shape) {
    shapes.push_back(p_shape);
}

void SGWorld2DInternal::remove_shape(SGShape2DInternal *p_shape) {
    shapes.erase(p_shape);
}

List<SGArea2DInternal *> *SGWorld2DInternal::get_overlapping_areas(SGArea2DInternal *p_area) const {
    List<SGArea2DInternal *> *ret = memnew(List<SGArea2DInternal *>);

    for (const List<SGArea2DInternal *>::Element *E = areas.front(); E; E = E->next()) {
        SGArea2DInternal *other_area = E->get();
        if (other_area == p_area) {
            continue;
        }

        if (p_area->overlaps(other_area)) {
            ret->push_back(other_area);
        }
    }

    return ret;
}

SGWorld2DInternal::SGWorld2DInternal()
{
    singleton = this;
}

SGWorld2DInternal::~SGWorld2DInternal() {
    singleton = nullptr;
}
