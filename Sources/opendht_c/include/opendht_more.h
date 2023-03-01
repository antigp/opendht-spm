//
//  Header.h
//  
//
//  Created by Eugene Antropov on 21.02.2023.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include "opendht_c.h"
#include <opendht/def.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

typedef struct dht_value_type dht_value_type;

typedef bool (*dht_filter_cb)(const dht_value* value, void* user_data);


// Get
OPENDHT_C_PUBLIC void dht_runner_get_with_filter(dht_runner* runner, const dht_infohash* hash, dht_get_cb cb, dht_done_cb done_cb, void* cb_user_data, dht_filter_cb filter_cb) ;

// Value
OPENDHT_C_PUBLIC void dht_value_set_id(dht_value* data, dht_value_id id);
OPENDHT_C_PUBLIC dht_value* dht_value_new_with_type(const uint8_t* data, size_t size, uint16_t type);
OPENDHT_C_PUBLIC uint16_t dht_value_get_valuetype_id(const dht_value* t);


// ValueTypes
OPENDHT_C_PUBLIC void dht_register_value_type(dht_runner* r, dht_value_type* t);
OPENDHT_C_PUBLIC dht_value_type* dht_value_type_default_userdata();
OPENDHT_C_PUBLIC uint16_t dht_get_valuetype_id(const dht_value_type* t);
OPENDHT_C_PUBLIC const char* dht_get_valuetype_name(const dht_value_type* t);
typedef bool (*dht_store_policy)(dht_infohash key, const dht_value* value, const dht_infohash from, const struct sockaddr* addr, socklen_t addr_len, void* cb_user_data);
typedef bool (*dht_edit_policy)(dht_infohash key, const dht_value* old_value, const dht_value* new_value, const dht_infohash from, const struct sockaddr* addr, socklen_t addr_len, void* cb_user_data);
OPENDHT_C_PUBLIC dht_value_type* dht_valuetype_new(uint16_t id, const char* name, uint32_t duration, dht_store_policy sp, dht_edit_policy ep, void* cb_user_data);


#ifdef __cplusplus
}
#endif
