#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "list.h"

/* Creates a list (node) and returns it
 * Arguments: The data the list will contain or NULL to create an empty
 * list/node and a CmpFunc
 */
llist* list_create(int (*CmpFunc)(list_node*,void*), void (*DpyFunc)(void * data)){
	if (!CmpFunc) return NULL;
	if (!DpyFunc) return NULL;

	llist *l = malloc(sizeof(llist));

	if (l != NULL) {
		l->CmpFunc = CmpFunc;
		l->DpyFunc = DpyFunc;
		l->node_number = 0;
		l->node = NULL;
	}

	return l;
}


void list_print(llist l){
	list_node *it;
	if (l.node == NULL){
		printf("La liste est vide !\n");
	} else {
		it = l.node;
		while(it != NULL){
			l.DpyFunc(it->data);
			it = it->next;
		}
	}
}

int list_isempty(llist l){
	return l.node_number == 0;
}



/* Completely destroys a list
 * Arguments: A pointer to a pointer to a list
 */
void list_destroy(llist *l)
{
	if (l) return;
	while (l->node != NULL) {
		list_pop(l);
	}
	free(l);
}


void list_empty(llist *l){
	while(!list_isempty(*l)){
		list_pop(l);
	}
}

list_node* list_node_create(void *data)
{
	if (!data) return NULL;
	list_node *node = malloc(sizeof(list_node));
	if (node) {
		node->data = data;
		node->next = NULL;
	}
	return node;
}

void list_node_destroy(list_node *node)
{
	if (node) {
		free(node);
	}
}



/* Creates a new list node and inserts it in the beginning of the list
 * Arguments: The list the node will be inserted to and the data the node will
 * contain
 */
list_node* list_insert_beginning(llist *l, void *data)
{
	if (!l) return NULL;
	list_node *new_node = list_node_create(data);
	if (new_node) {
		new_node->next = l->node;
		l->node = new_node;
		l->node_number++;
	}
	return new_node;
}

/* Creates a new list node and inserts it at the end of the list
 * Arguments: The list the node will be inserted to and the data the node will
 * contain
 */
list_node* list_insert_end(llist *l, void *data)
{
	if (!l) return NULL;
	list_node *new_node = list_node_create(data);
	if (new_node) {
		if (l->node == NULL){
			l->node = new_node;
		}else{
			for(list_node *it = l->node; it; it = it->next) {
				if (it->next == NULL) {
					it->next = new_node;
					break;
				}
			}
		}
		l->node_number++;
	}
	return new_node;
}

/* Removes a node from the list
 * Arguments: The list and the node that will be removed
 */
void list_remove(llist *l, list_node *node){

	if (l != NULL && node != NULL){
		list_node *tmp = l->node;

		while (tmp->next != NULL && tmp->next != node){
			tmp = tmp->next;
		}

		if (tmp->next != NULL) {
			tmp->next = node->next;
			list_node_destroy(node);
			node = NULL;
			l->node_number--;
		}

	}
	
}

/* Find an element in a list by the pointer to the element
 * Arguments: A pointer to a list and a pointer to the node/element
 */
list_node* list_find_node(llist *l, list_node *node)
{
	if (!l) return NULL;
	for (list_node *it = l->node; it; it = it->next)
		{ if (it == node) return it; }
	return NULL;
}

list_node* list_find_by_data(llist *l, void *data)
{
	if (!l) return NULL;
	for (list_node *it = l->node; it; it = it->next)
		{ if (l->CmpFunc(it, data)) return it; }
	return NULL;
}

/* Finds a node in a list by the data pointer
 * Arguments: A pointer to a list and a pointer to the data
 */
list_node* list_find_by_data_ptr(llist *l, void *data)
{
	if (!l) return NULL;
	for (list_node *it = l->node; it; it = it->next)
		{ if (it->data == data) return it; }
	return NULL;
}

void *list_pop(llist *l)
{
	void *data = NULL;
	list_node *tmp_node = NULL;
	if (l) {
		tmp_node = l->node;
		data = tmp_node->data;
		l->node = tmp_node->next;
		list_node_destroy(tmp_node);
		l->node_number--;
	}
	return data;
}

