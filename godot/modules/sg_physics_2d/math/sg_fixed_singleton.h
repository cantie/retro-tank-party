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

#ifndef SG_FIXED_SINGLETON_H
#define SG_FIXED_SINGLETON_H

#include <core/object.h>

#include "sg_fixed_vector2.h"

class SGFixed : public Object {

    GDCLASS(SGFixed, Object);

    static SGFixed *singleton;

protected:
    static void _bind_methods();

public:
    static SGFixed *get_singleton();

    int from_int(int p_int_value) const;
    int from_float(float p_float_value) const;

    int to_int(int p_fixed_value) const;
    float to_float(int p_fixed_value) const;

    int mul(int p_fixed_one, int p_fixed_two) const;
    int div(int p_fixed_one, int p_fixed_two) const;

    Ref<SGFixedVector2> vector2(int p_fixed_x, int p_fixed_y) const;

    SGFixed();
    ~SGFixed();
};

#endif
