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

#include "sg_broadphase_2d_internal.h"

void SGBroadphase2DInternal::_add_element_to_cells(Element *p_element) {
	// @todo Implement!
}

void SGBroadphase2DInternal::_remove_element_from_cells(Element *p_element) {
	p_element->indices.clear();
	// @todo Implement!
}

SGBroadphase2DInternal::Element *SGBroadphase2DInternal::create_element(SGCollisionObject2DInternal *p_object) {
	Element *element = memnew(Element);
	elements.push_back(element);

	element->object = p_object;
	//element->bounds = p_object->get_bounds();
	_add_element_to_cells(element);

	return element;
}

void SGBroadphase2DInternal::update_element(Element *p_element) {
	_remove_element_from_cells(p_element);
	_add_element_to_cells(p_element);
}

void SGBroadphase2DInternal::delete_element(Element *p_element) {
	_remove_element_from_cells(p_element);
	memdelete(p_element);
}

Set<SGCollisionObject2DInternal *> *SGBroadphase2DInternal::find_nearby(const fixed_rect2 &p_bounds) const {
	Set<SGCollisionObject2DInternal *> *results = memnew(Set<SGCollisionObject2DInternal *>);

	// @todo Implement!

	return results;
}

void SGBroadphase2DInternal::set_cell_size(int p_cell_size) {
	if (cell_size != p_cell_size) {
		cell_size = p_cell_size;

		cells.clear();
		for (List<Element *>::Element *E = elements.front(); E; E = E->next()) {
			Element *element = E->get();
			element->indices.clear();
			_add_element_to_cells(element);
		}
	}
}

SGBroadphase2DInternal::SGBroadphase2DInternal(int p_cell_size) {
	cell_size = p_cell_size;
}

SGBroadphase2DInternal::~SGBroadphase2DInternal() {
	for (List<Element *>::Element *E = elements.front(); E; E = E->next()) {
		memdelete(E->get());
	}
}
