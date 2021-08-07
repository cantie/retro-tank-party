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

#ifndef SG_AREA_2D_H
#define SG_AREA_2D_H

#include <scene/2d/node_2d.h>

#include "../../math/sg_fixed_vector2.h"

class SGArea2D : public Node2D {
    GDCLASS(SGArea2D, Node2D);

    Ref<SGFixedVector2> fixed_position;
    bool updating_position;

protected:
    static void _bind_methods();
    void _notification(int p_what);

	virtual void _changed_callback(Object *p_changed, const char *p_prop) override;

public:

    void set_fixed_position(const Ref<SGFixedVector2> &p_fixed_position);
    Ref<SGFixedVector2> get_fixed_position();

    void sync_to_physics();
    bool overlaps_area();

    SGArea2D();

};

#endif