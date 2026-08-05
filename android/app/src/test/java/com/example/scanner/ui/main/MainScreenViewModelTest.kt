package com.example.scanner.ui.main

import com.example.scanner.data.DataRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class MainScreenViewModelTest {

  private val dispatcher = StandardTestDispatcher()

  @Before
  fun setUp() {
    // stateIn collects in viewModelScope (Dispatchers.Main), so map Main to the test scheduler.
    Dispatchers.setMain(dispatcher)
  }

  @After
  fun tearDown() {
    Dispatchers.resetMain()
  }

  @Test
  fun uiState_initialValue_isLoading() = runTest(dispatcher) {
    val viewModel = MainScreenViewModel(FakeRepository(flowOf(listOf("Sample"))))
    assertEquals(MainScreenUiState.Loading, viewModel.uiState.value)
  }

  @Test
  fun uiState_repositoryEmitsData_isSuccess() = runTest(dispatcher) {
    val viewModel = MainScreenViewModel(FakeRepository(flowOf(listOf("Android", "Kotlin"))))
    val state = viewModel.uiState.first { it is MainScreenUiState.Success }
    assertEquals(listOf("Android", "Kotlin"), (state as MainScreenUiState.Success).data)
  }

  @Test
  fun uiState_repositoryThrows_isError() = runTest(dispatcher) {
    val viewModel = MainScreenViewModel(FakeRepository(flow { throw RuntimeException("boom") }))
    val state = viewModel.uiState.first { it is MainScreenUiState.Error }
    assertEquals("boom", (state as MainScreenUiState.Error).throwable.message)
  }
}

private class FakeRepository(private val dataFlow: Flow<List<String>>) : DataRepository {
  override val data: Flow<List<String>> = dataFlow
}
