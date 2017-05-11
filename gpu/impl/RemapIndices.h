
/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the CC-by-NC license found in the
 * LICENSE file in the root directory of this source tree.
 */

// Copyright 2004-present Facebook. All Rights Reserved.

#pragma once

#include <vector>

namespace faiss { namespace gpu {

/// Utility function to translate (list id, offset) to a user index on
/// the CPU. In a cpp in order to use OpenMP.
void ivfOffsetToUserIndex(
  long* indices,
  int numLists,
  int queries,
  int k,
  const std::vector<std::vector<long>>& listOffsetToUserIndex);

} } // namespace
